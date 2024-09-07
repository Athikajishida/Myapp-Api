class UsersController < ApplicationController
  before_action :authorize_request, except: [:login, :register]

  def register
    # binding.pry
    @user = User.new(user_params.merge(admin: false))

    if @user.save
      token = JsonWebToken.encode(user_id: @user.id)
      render json: { token: token, user: @user }, status: :created
    else
      Rails.logger.error("User registration failed: #{@user.errors.full_messages}")
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    @user = User.find_by(email: params[:email])
    if @user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: @user.id,admin: @user.admin)
      render json: { token: token, user: @user }, status: :ok
    else
      render json: { errors: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def show
    render json: current_user
  end

  def update
    if current_user.nil?
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end
    Rails.logger.info("Updating user with params: #{user_params.inspect}")

    if current_user.update(user_params)
      render json: {
        message: "User updated successfully",
        user: current_user,
        profile_photo_url: url_for(current_user.profile_photo) # Active Storage URL helper
      }, status: :ok
    else
      render json: { error: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def logout
    # Logout logic depends on client-side implementation
    render json: { message: "Logged out" }, status: :ok
  end
  
  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :profile_image)  
  end

  def authorize_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    decoded = JsonWebToken.decode(header)
    @current_user = User.find(decoded[:user_id]) if decoded
  rescue ActiveRecord::RecordNotFound
    render json: { errors: 'User not found' }, status: :unauthorized
  rescue JWT::DecodeError
    render json: { errors: 'Invalid token' }, status: :unauthorized
  end

  def current_user
    @current_user
  end
end
