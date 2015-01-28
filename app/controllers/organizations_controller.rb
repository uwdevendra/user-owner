class OrganizationsController < ApplicationController
  load_and_authorize_resource :except => :create
  require_password_confirmation_for :destroy

  def new
    @organization = Organization.new.decorate
    @user = @organization.users.new
  end

  def create
    @organization = Organization.build(params[:organization],
                                       params[:organization][:users])

    @organization.default_locale = I18n.locale.to_s

    if @organization.save
      # redirect_to root_path
      # redirect_to organizations_path(:org_id => @organization.users.first)
      redirect_to organizations_path
      flash[:notice] = t("successful_create_message")
    else
      @organization = @organization.decorate
      @user = @organization.users.first
      flash[:error] = t("creation_failed")
      render :new
    end
  end

  def edit
    @organization = Organization.find(params[:id])
    # added @users_count to show in summary section as per new design
    @users_count = @organization.users
  end

  def update
    organization = Organization.find(params[:id])
    organization.update_attributes(params[:organization])
    flash[:notice] = t("organizations.update.successful_organization_edit_flash_notice")
    redirect_to organization_path
  end

  def index
    # @org = params[:org_id]
  end

  def show
    # @organization = Organization.find_by_id(params[:id])
    redirect_to(:controller =>  "organizations" , :action => "edit")
    # redirect_to(:controller =>  "organizations" , :action => "edit" , :organization_id => @organization.id)
    @organization = Organization.find_by_id(params[:id])
  end

  def activate
    organization = Organization.find(params[:organization_id])
    organization.activate
    UserMailer.delay(:queue => "organization_activation_mail").activation_mail(organization.cso_admins.first, organization.default_locale)
    flash[:notice] = t "status_changed", :organization_name => organization.name, :status => organization.status
    redirect_to organizations_path
  end

  def deactivate
    organization = Organization.find(params[:organization_id])
    organization.deactivate
    UserMailer.delay(:queue => "organization_deactivation_mail").deactivation_mail(organization.cso_admins.first, organization.default_locale, params[:deactivate_message])
    flash[:notice] = t "status_changed", :organization_name => organization.name, :status => organization.status
    redirect_to organizations_path
  end

  def destroy
    organization = Organization.find(params[:id])
    organization.soft_delete_self_and_associated
    reset_session
    flash[:notice] = I18n.t("organizations.destroy.organization_to_be_deleted")
    redirect_to root_path
  end
end
