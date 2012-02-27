class Api::V1::ProjectsController < Api::V1::BaseController
  before_filter :find_project, :only => [:show]

  before_filter :add_project_abilities
  before_filter :authorize_read_project!

  def show
    respond_with(@project)
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
