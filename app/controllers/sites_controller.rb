class SitesController < ApplicationController
  before_action :set_site, only: [:show, :edit, :update, :destroy]

  def crawl
    redirect_to '/site_pages', notice: 'Site page was successfully created.'
  end

  def detect_unuse
    uploaded_file =  params['fileupload']['file']
    inputs = uploaded_file.read
    @unuse_files = []
    inputs.each_line do |file_path|
      if Page.of_primal_sites.active.where(path: file_path.chomp).blank?
        #不要コンテンツ
        UnuseFile.find_or_create_by!(path: file_path.chomp)
      end
    end
  end

  # GET /sites
  # GET /sites.json
  def index
    @sites = Site.all.order(:id)
  end

  # GET /sites/1
  # GET /sites/1.json
  def show
  end

  # GET /sites/new
  def new
    @site = Site.new
  end

  # GET /sites/1/edit
  def edit
  end

  # POST /sites
  # POST /sites.json
  def create
    @site = Site.new(site_params)

    respond_to do |format|
      if @site.save
        format.html { redirect_to @site, notice: 'Site was successfully created.' }
        format.json { render :show, status: :created, location: @site }
      else
        format.html { render :new }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    respond_to do |format|
      if @site.update(site_params)
        format.html { redirect_to @site, notice: 'Site was successfully updated.' }
        format.json { render :show, status: :ok, location: @site }
      else
        format.html { render :edit }
        format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sites/1
  # DELETE /sites/1.json
  def destroy
    @site.destroy
    respond_to do |format|
      format.html { redirect_to sites_url, notice: 'Site was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_site
      @site = Site.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def site_params
      params.require(:site).permit(:domain, :name, :url)
    end
end
