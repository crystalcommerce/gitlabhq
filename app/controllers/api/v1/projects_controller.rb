class Api::V1::ProjectsController < Api::V1::BaseController
  before_filter :find_project, :only => [:show]

  before_filter :add_project_abilities
  before_filter :authorize_read_project!, :except => [:create]

  def show
    respond_with(@project)
  end

  def create
    project = Project.new(params[:project])
    project.owner = current_user

    begin
      Project.transaction do
        project.save!
        project.users_projects.create!(:project_access => UsersProject::MASTER,
                                       :user => current_user)

        project.update_repository
      end
    rescue ActiveRecord::RecordInvalid
    end

    if project.valid?
      respond_with(project, :location => api_v1_project_path(project.code))
    else
      respond_with(project)
    end
  rescue Gitlabhq::Gitolite::AccessDenied
    error = { :error => "An error with the git host prevented the project from being created." }
    respond_with(error, :status => 500)
  end

  private
  def render_404
    error = { :error => "The project you were looking for could not be found."}
    respond_with(error, :status => 404)
  end

  def find_project
    @project = Project.find_by_code(params[:id])
  end
end
