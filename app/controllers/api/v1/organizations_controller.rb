module Api
  module V1
    class OrganizationsController < ActionController::Base
      skip_authorize_resource
      doorkeeper_for :all
      respond_to :json

      def index
        organizations = Organization.active_organizations
        # organizations = Organization.all
        respond_with organizations.to_json(:only => [:id, :name])
        # puts organizations.to_json(:only => [:id, :name, :logo,:status]).inspect
        # respond_with organizations.to_json
      end

      def validate_orgs
        org_ids = JSON.parse(params[:org_ids])
        respond_with Organization.valid_ids?(org_ids).to_json
      end

      def show
        organization = Organization.find_by_id(params[:id])
        if(organization)
          render :json => organization.decorate.to_json
        else
          render :nothing => true, :status => :bad_request
        end
      end
    end
  end
end
