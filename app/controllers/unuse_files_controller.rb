class UnuseFilesController < ApplicationController
  before_action :set_unuse_file, only: [:show, :edit, :update, :destroy]

  def download
    send_data(UnuseFile.export, filename: "unusefiles-#{Date.today}.csv")
  end
  def check
    UnuseFile.unchecked.each do |unuse_file|
      logger.info 'loopの先頭'
      active_detected = false
      Site.primal.each do |site|
        %w(mobile pc).each do |device_type|
          if site.deletable_contents?(unuse_file.path, device_type)
            #不要コンテンツ
            logger.info '不要コンテンツ'
          else
            #リンクは無いが閲覧可能なコンテンツ
            logger.info '不要では無いコンテンツ!'
            unuse_file.update_attributes!(active_site_id: site.id, active_device_type: device_type)
            active_detected = true
          end
          break if active_detected == true
        end
        break if active_detected == true
      end
    end
  end

  # GET /unuse_files
  # GET /unuse_files.json
  def index
    @unuse_files = UnuseFile.all.order([:active_site_id,:path, :active_device_type])
  end

  # GET /unuse_files/1
  # GET /unuse_files/1.json
  def show
  end

  # GET /unuse_files/new
  def new
    @unuse_file = UnuseFile.new
  end

  # GET /unuse_files/1/edit
  def edit
  end

  # POST /unuse_files
  # POST /unuse_files.json
  def create
    @unuse_file = UnuseFile.new(unuse_file_params)

    respond_to do |format|
      if @unuse_file.save
        format.html { redirect_to @unuse_file, notice: 'Unuse file was successfully created.' }
        format.json { render :show, status: :created, location: @unuse_file }
      else
        format.html { render :new }
        format.json { render json: @unuse_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /unuse_files/1
  # PATCH/PUT /unuse_files/1.json
  def update
    respond_to do |format|
      if @unuse_file.update(unuse_file_params)
        format.html { redirect_to @unuse_file, notice: 'Unuse file was successfully updated.' }
        format.json { render :show, status: :ok, location: @unuse_file }
      else
        format.html { render :edit }
        format.json { render json: @unuse_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /unuse_files/1
  # DELETE /unuse_files/1.json
  def destroy
    @unuse_file.destroy
    respond_to do |format|
      format.html { redirect_to unuse_files_url, notice: 'Unuse file was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unuse_file
      @unuse_file = UnuseFile.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def unuse_file_params
      params.require(:unuse_file).permit(:path)
    end
end
