class LinkFromTosController < ApplicationController
  before_action :set_link_from_to, only: [:show, :edit, :update, :destroy]

  # GET /link_from_tos
  # GET /link_from_tos.json
  def index
    @link_from_tos = LinkFromTo.all
  end

  # GET /link_from_tos/1
  # GET /link_from_tos/1.json
  def show
  end

  # GET /link_from_tos/new
  def new
    @link_from_to = LinkFromTo.new
  end

  # GET /link_from_tos/1/edit
  def edit
  end

  # POST /link_from_tos
  # POST /link_from_tos.json
  def create
    @link_from_to = LinkFromTo.new(link_from_to_params)

    respond_to do |format|
      if @link_from_to.save
        format.html { redirect_to @link_from_to, notice: 'Link from to was successfully created.' }
        format.json { render :show, status: :created, location: @link_from_to }
      else
        format.html { render :new }
        format.json { render json: @link_from_to.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /link_from_tos/1
  # PATCH/PUT /link_from_tos/1.json
  def update
    respond_to do |format|
      if @link_from_to.update(link_from_to_params)
        format.html { redirect_to @link_from_to, notice: 'Link from to was successfully updated.' }
        format.json { render :show, status: :ok, location: @link_from_to }
      else
        format.html { render :edit }
        format.json { render json: @link_from_to.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /link_from_tos/1
  # DELETE /link_from_tos/1.json
  def destroy
    @link_from_to.destroy
    respond_to do |format|
      format.html { redirect_to link_from_tos_url, notice: 'Link from to was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_link_from_to
      @link_from_to = LinkFromTo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def link_from_to_params
      params.require(:link_from_to).permit(:from_page_id, :to_page_id, :by_redirection)
    end
end
