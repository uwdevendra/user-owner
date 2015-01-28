
module Api
  module V1
    class UsersController < ActionController::Base
      doorkeeper_for :all
      load_and_authorize_resource :user, :parent => false, :except => [:validate_users, :index]
      respond_to :json

      def me
        respond_with current_user.to_json(:except => :password_digest,
                                          :include => { :organization => { :only => [:org_type, :name] }})
      end

      def index
        organization = Organization.find_by_id(params[:organization_id])
        authorize! :read, organization
        users = organization.users.active_users
        user_ids = params[:user_ids]
        users = users.where(:id => user_ids) if user_ids
        respond_with users.to_json(:only => [:id, :name, :role, :email])
      end

      def users_for_ids
        user_ids = JSON.parse params[:user_ids]
        users = User.where(:id => user_ids) if user_ids
        respond_with users.to_json(:only => [:id, :name, :email, :role])
      end

     def validate_users
       authorize! :read, User
       user_ids = JSON.parse(params[:user_ids])
       respond_with User.valid_ids?(user_ids).to_json
     end

      private

      def current_user
        @current_user ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
      end
    end
  end
end
