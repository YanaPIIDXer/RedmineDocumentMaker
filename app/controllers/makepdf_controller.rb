class MakepdfController < ApplicationController
  unloadable
  before_filter :find_project
  
  def make
    maker = MakepdfHelper::PDFMaker.new(@project)

    # 各種ページの生成
    maker.makeMilestonePage()   # マイルストーン
    maker.makeGanttChartPage()  # ガントチャート

    send_data(maker.generate(), :type => "application/pdf", :filename => 'document.pdf')
  end

private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
