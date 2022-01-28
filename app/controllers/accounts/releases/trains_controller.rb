class Accounts::Releases::TrainsController < ApplicationController
  before_action :set_app, only: %i[new create show index edit update activate]
  before_action :set_train, only: %i[show edit update activate]

  def new
    @train = @app.trains.new
  end

  def create
    @train = @app.trains.new(parsed_train_params)

    respond_to do |format|
      if @train.save
        format.html {
          redirect_to accounts_organization_app_releases_train_path(current_organization, @app, @train),
                      notice: "Train was successfully created."
        }
        format.json { render :show, status: :created, location: @train }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @train.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    return if @train.status.running?

    respond_to do |format|
      if @train.update(parsed_train_params)
        format.html {
          redirect_to accounts_organization_app_path(current_organization, @train),
                      notice: "Train was successfully updated."
        }
        format.json { render :show, status: :ok, location: @train }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @train.errors, status: :unprocessable_entity }
      end
    end
  end

  def activate
    @train.activate!
  end

  def edit
  end

  def show
  end

  def index
  end

  private

  def set_train
    @train = @app.trains.friendly.find(params[:id])
  end

  def set_app
    @app = current_organization.apps.friendly.find(params[:app_id])
  end

  def train_params
    params.require(:releases_train).permit(
      :name,
      :description,
      :working_branch,
      :version_seeded_with,
      :version_suffix,
      :kickoff_at,
      :repeat_duration_value,
      :repeat_duration_unit
    )
  end

  def parsed_train_params
    train_params
      .merge(repeat_duration: repeat_duration(train_params))
      .merge(status: Releases::Train.statuses[:inactive])
      .except(:repeat_duration_value, :repeat_duration_unit)
  end

  def repeat_duration(train_params)
    ActiveSupport::Duration.parse(
      Duration.new(train_params[:repeat_duration_unit].to_sym =>
                     train_params[:repeat_duration_value].to_i).iso8601
    )
  end
end