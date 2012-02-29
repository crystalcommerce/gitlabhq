require 'spec_helper'

describe "/api/v1/projects", :type => :api do
  context "show" do
    let(:project) { Factory(:project) }
    let(:owner) { project.owner }
    let(:url) { "/api/v1/projects/#{project.code}"}

    before do
      project.add_access(owner, :read)
    end

    it "returns the project in JSON with a correct request" do
      get url, {:private_token => owner.private_token},
               {'HTTP_ACCEPT' => 'application/json'}
      last_response.body.should == project.to_json
      last_response.status.should == 200
    end

    it "returns a 401 if the token is invalid" do
      get url, {:private_token => "cats"},
               {'HTTP_ACCEPT' => 'application/json'}
      last_response.body.should == {
        'error' => 'Invalid authentication token.'
      }.to_json
      last_response.status.should == 401
    end

    it "returns a 404 if the token is valid but the user does not have access" do
      user2 = user_with_role(:user)
      get url, {:private_token => user2.private_token},
               {'HTTP_ACCEPT' => 'application/json'}
      last_response.body.should == {
        'error' => 'The project you were looking for could not be found.'
      }.to_json
      last_response.status.should == 404
    end

    it "returns a 404 if the project cannot be found" do
      get "/api/v1/projects/cats", {:private_token => owner.private_token},
                                   {'HTTP_ACCEPT' => 'application/json'}
      last_response.body.should == {
        'error' => 'The project you were looking for could not be found.'
      }.to_json
      last_response.status.should == 404
    end
  end

  context "create" do
    let(:admin) { user_with_role(:admin) }
    let(:url) { "/api/v1/projects" }

    it "creates the project and redirects to the resource" do
      expect do
        post url, {
                    :private_token => admin.private_token,
                    :project => {
                      :name => 'NewProject',
                      :code => 'NPR',
                      :path => 'newproject'
                    }
                  },
                  {'HTTP_ACCEPT' => 'application/json'}
      end.to change { Project.count }.by(1)

      project = Project.find_by_code('NPR')

      last_response.status.should == 201
      last_response.headers["Location"].should == "/api/v1/projects/NPR"
      last_response.body.should == project.to_json
    end

    it "responds with the errors if the request was invalid" do
      expect do
        post url, {
                    :private_token => admin.private_token,
                    :project => {}
                  },
                  {'HTTP_ACCEPT' => 'application/json'}
      end.to change { Project.count }.by(0)

      last_response.status.should == 422
      last_response.body.should == {
        'errors' => {
          'name' => ["can't be blank"],
          'path' => ["can't be blank"],
          'code' => ["can't be blank", "is too short (minimum is 3 characters)"]
        }
      }.to_json
    end
  end

  context "index" do
    let(:url)     { "/api/v1/projects" }

    it "returns a list of all of the user's projects" do
      project1 = Factory(:project)
      owner = project1.owner
      project2 = Factory(:project,
                         :owner => owner,
                         :name => 'foo',
                         :code => 'foo',
                         :path => 'foo')
      projects = [project1, project2]
      projects.each {|p| p.add_access(owner, :read)}
      Factory(:project, :name => 'bar', :code => 'bar', :path => 'bar')

      get url, {:private_token => owner.private_token},
               {'HTTP_ACCEPT' => 'application/json'}
      last_response.body.should == projects.to_json
      last_response.status.should == 200
    end
  end
end
