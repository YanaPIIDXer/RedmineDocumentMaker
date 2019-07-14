class MakepdfController < ApplicationController
  unloadable
  before_filter :find_project
  
  def make
    maker = MakepdfHelper::PDFMaker.new(@project)

    desiredReward = params[:desiredReward]
    if !desiredReward
      desiredReward = 0
    end
    
    # 各種ページの生成
    maker.makeMilestonePage()                      # マイルストーン
    maker.makeConditionNoticePage(desiredReward)   # 条件掲示
    maker.makeGanttChartPage()                     # ガントチャート

    send_data(maker.generate(), :type => "application/pdf", :filename => 'document.pdf')
  end

private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
