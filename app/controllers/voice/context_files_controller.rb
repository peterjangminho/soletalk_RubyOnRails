module Voice
  class ContextFilesController < ApplicationController
    before_action :authenticate_user!

    def index
      @uploaded_files = current_user.uploaded_files.order(created_at: :desc)
    end

    def create
      file = params[:file]

      if file.blank?
        respond_to do |format|
          format.json { render json: { status: "error", message: "No file provided" }, status: :unprocessable_entity }
          format.html { redirect_to voice_context_files_path, alert: t("flash.context_files.create.no_file") }
        end
        return
      end

      current_user.uploaded_files.attach(file)

      respond_to do |format|
        format.json { render json: { status: "ok", filename: file.original_filename } }
        format.html { redirect_to voice_context_files_path, notice: t("flash.context_files.create.notice") }
      end
    end
  end
end
