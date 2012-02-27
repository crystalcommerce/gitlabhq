require 'spec_helper'

describe "/api/v1/projects", :type => :api do
  context "show" do
    let(:project) { Factory(:project) }
    let(:owner) { project.owner }
    let(:url) { "/api/v1/projects/#{project.id}"}

    before do
      project.add_access(owner, :read)
    end

    it "returns the project in JSON with a correct request" do
      get url, {:private_token => owner.private_token}, {'HTTP_ACCEPT' => 'application/json'}
      last_response.body.should == project.to_json
      last_response.status.should == 200
    end

    it "returns a 401 if the token is invalid" do
      get url, {:private_token => "cats"}, {'HTTP_ACCEPT' => 'application/json'}
      last_response.body.should == {
        'error' => 'Invalid authentication token.'
      }.to_json
      last_response.status.should == 401
    end

    it "returns a 404 if the token is valid but the user does not have access" do
      user2 = user_with_role(:user)
      get url, {:private_token => user2.private_token}, {'HTTP_ACCEPT' => 'application/json'}
      last_response.body.should == {
        'error' => 'The project you were looking for could not be found.'
      }.to_json
      last_response.status.should == 404
    end
  end
end
