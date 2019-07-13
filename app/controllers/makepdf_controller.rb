class MakepdfController < ApplicationController
  unloadable

  attr_accessor :project

  def make
    # PDFの作り方・・・と言うか、PDFクラスについての情報は以下を参照。
    # https://github.com/naitoh/rbpdf/
    
    pdf = ::Redmine::Export::PDF::ITCPDF::new(current_language)
    pdf.SetTitle("#{project}_document")
    pdf.set_margins(15, 27, 15)
    pdf.add_page()
    pdf.write(5, params[:headText], '')

    send_data(pdf.output(), :filename => 'document.pdf')
  end

end
