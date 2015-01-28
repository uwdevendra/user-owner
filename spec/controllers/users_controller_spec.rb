require 'spec_helper'

describe UsersController do
  before(:each) do
    @organization = FactoryGirl.create(:organization)
    user = FactoryGirl.build(:user)
    user.role = "cso_admin"
    user.organization_id = @organization.id
    user.save
    sign_in_as(user)
  end

  context "GET 'new'" do
    it "renders the 'new' template" do
      get :new, :organization_id => @organization.id

      response.should be_ok
      response.should render_template :new
    end

    it "assigns a blank user" do

      get :new, :organization_id => @organization.id
      assigns(:user).should be_a(User)
    end
  end

  context "GET 'index'" do
    it "renders the 'index' template" do
      get :index, :organization_id => @organization.id

      response.should be_ok
      response.should render_template :index
    end

    it "lists all the users of the given organization" do
      user = FactoryGirl.create(:user, :organization => @organization, :status => User::Status::ACTIVE)
      get :index, :organization_id => @organization
      response.should be_ok
      assigns(:users).should == @organization.users
    end
  end

  context "POST 'create'" do

    it  "assigns an instance variable for the user" do
      user = FactoryGirl.attributes_for(:user)
      post :create, :organization_id => @organization.id, :user => user
      assigns(:user).should be_a(User)
    end

    context "when save is successful" do
      it "creates a new user" do
        user = FactoryGirl.attributes_for(:user)
        expect do
          post :create, :organization_id => @organization.id, :user => user
        end.to change { User.count }.by(1)
      end

      it "saves the user's email in lower case irrespective of the case" do
        user = FactoryGirl.attributes_for(:user, :email => "ABC@test.com")
        post :create, :organization_id => @organization.id, :user => user
        User.last.email.should == "abc@test.com"
      end

      it "assigns the proper organization ID for the user" do

        user = FactoryGirl.attributes_for(:user)
        post :create, :organization_id => @organization.id, :user => user
        User.last.organization_id.should == @organization.id
      end

      it "assigns the role for the user as 'field_agent'" do

        user = FactoryGirl.attributes_for(:user)
        post :create, :organization_id => @organization.id, :user => user
        User.last.role.should == 'field_agent'
      end

      it "assigns a random password for the user" do
        user = {:name => "foo", :email => "smittty@baz.com"}
        post :create, :organization_id => @organization.id, :user => user
        User.find_by_email("smittty@baz.com").authenticate("123").should be_false
      end

      it "assigns the status for the user as 'pending'" do

        user = FactoryGirl.attributes_for(:user)
        post :create, :organization_id => @organization.id, :user => user
        User.last.status.should == User::Status::PENDING
      end

      it "should redirect to the root page" do

        user = FactoryGirl.attributes_for(:user)
        post :create, :organization_id => @organization.id, :user => user
        response.should redirect_to(root_path)
        flash[:notice].should_not be_nil
      end

      it "generates a password token at creation of user" do
        user = FactoryGirl.attributes_for(:user)
        post :create, :organization_id => @organization.id, :user => user
        User.find_by_email(user[:email]).password_reset_token.should_not be_nil
      end

      it "sends a mail to given user with password link" do
        ActionMailer::Base.deliveries.clear
        user = FactoryGirl.attributes_for(:user)
        post :create, :organization_id => @organization.id, :user => user
        Delayed::Worker.new.work_off
        ActionMailer::Base.deliveries.should_not be_empty
        email = ActionMailer::Base.deliveries.first
        email.to.should include(user[:email])
      end
    end

    context "when save is unsuccessful" do
      it "should re-render the new page" do

        user = FactoryGirl.attributes_for(:user).delete('name')
        post :create, :organization_id => @organization.id, :user => user
        response.should render_template(:new)
      end
    end
  end

  context "GET 'edit'" do
    it "assigns the user" do
      user = FactoryGirl.create(:user, :organization => @organization)
      get :edit, :id => user.id, :organization_id => @organization.id
      response.should be_ok
      assigns(:user).should == user
    end

    it "assigns the organization" do
      user = FactoryGirl.create(:user, :organization => @organization)
      get :edit, :id => user.id, :organization_id => @organization.id
      response.should be_ok
      assigns(:organization).should == @organization
    end

    it "renders the edit page" do
      user = FactoryGirl.create(:user, :organization => @organization)
      get :edit, :id => user.id, :organization_id => @organization.id
      response.should render_template :edit
    end
  end

  context "PUT 'update'" do
    it "updates the user" do
      user = FactoryGirl.create(:user, :organization => @organization, :role => "field_agent")
      put :update, :id => user.id, :organization_id => @organization.id, :user => {:role => "cso_admin"}
      user.reload.role.should == "cso_admin"
    end

    it "redirects to the users' index page on success" do
      user = FactoryGirl.create(:user, :organization => @organization, :role => "field_agent")
      put :update, :id => user.id, :organization_id => @organization.id, :user => {:role => "cso_admin"}
      response.should redirect_to organization_users_path :organization_id => @organization.id
      flash[:notice].should_not be_nil
    end

    it "renders the :edit page if there's an error" do
      user = FactoryGirl.create(:user, :organization => @organization, :role => "field_agent")
      put :update, :id => user.id, :organization_id => @organization.id, :user => {:email => nil}
      response.should render_template :edit
      flash[:error].should_not be_nil
    end
  end
end
