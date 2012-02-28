class Api::V1::BaseController < ActionController::Base
  before_filter :authenticate_user!
  before_filter :set_current_user_for_mailer

  respond_to :json

  helper_method :abilities, :can?

  rescue_from Gitlabhq::Gitolite::AccessDenied do |exception|
    render :file => File.join(Rails.root, "public", "githost_error"), :layout => false
  end

  protected

  def set_current_user_for_mailer
    MailerObserver.current_user = current_user
  end

  def abilities
    @abilities ||= Six.new
  end

  def can?(object, action, subject)
    abilities.allowed?(object, action, subject)
  end

  def project
    @project ||= Project.find_by_code(params[:project_id])
  end

  def add_project_abilities
    abilities << Ability
  end

  def authenticate_admin!
    return render_404 unless current_user.is_admin?
  end

  def authorize_project!(action)
    return render_404 unless can?(current_user, action, project)
  end

  def authorize_code_access!
    return render_404 unless can?(current_user, :download_code, project)
  end

  def access_denied!
    render_404
  end

  def method_missing(method_sym, *arguments, &block)
    if method_sym.to_s =~ /^authorize_(.*)!$/
      authorize_project!($1.to_sym)
    else
      super
    end
  end

  def load_refs
    unless params[:ref].blank?
      @ref = params[:ref]
    else
      @branch = params[:branch].blank? ? nil : params[:branch]
      @tag = params[:tag].blank? ? nil : params[:tag]
      @ref = @branch || @tag || @project.try(:default_branch) || Repository.default_ref
    end
  end

  def render_404
    render :file => File.join(Rails.root, "public", "404"), :layout => false, :status => "404"
  end

  def require_non_empty_project
    redirect_to @project unless @project.repo_exists? && @project.has_commits?
  end

  def no_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
