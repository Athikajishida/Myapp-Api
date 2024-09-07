class Admin::UsersController < ApplicationController
  before_action :authorize_admin_request

  def index
    @users = User.all
    render json: @users
  end
  def create
    user = User.new(user_params)
    if user.save
      render json: user, status: :created
    else
      render json: { error: user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end
  def block
    user = User.find(params[:id])
    user.update(blocked: true)
    render json: { message: 'User blocked' }
  end

  def unblock
    user = User.find(params[:id])
    user.update(blocked: false)
    render json: { message: 'User unblocked' }
  end

  def update
    user = User.find(params[:id])
    if user.update(user_params)
      render json: user
    else
      render json: { error: user.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    head :no_content
  end

  private

  def authorize_admin_request
    header = request.headers['Authorization']
    token = header.split(' ').last if header.present?

    begin
      decoded = JsonWebToken.decode(token)
      @current_user = User.find(decoded[:user_id])
      render json: { errors: 'Access denied' }, status: :forbidden unless @current_user.admin?
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Admin not found' }, status: :unauthorized
    rescue JWT::DecodeError
      render json: { errors: 'Invalid token' }, status: :unauthorized
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :admin, :blocked)
  end
end
