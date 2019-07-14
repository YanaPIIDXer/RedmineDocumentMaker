class MakepdfController < ApplicationController
  unloadable
  before_filter :find_project
  
  def make
    maker = MakepdfHelper::PDFMaker.new(@project)

    send_data(maker.generate(), :type => "application/pdf", :filename => 'document.pdf')
  end

private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
