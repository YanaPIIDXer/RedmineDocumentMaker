Redmine::Plugin.register :document_maker do
  name 'ドキュメント生成'
  author 'YanaP'
  description 'ドキュメントをPDF形式で生成する為のプラグインです。'
  version '1.0.0'
  url 'https://github.com/YanaPIIDXer/RedmineDocumentMaker'
  author_url 'https://github.com/YanaPIIDXer'

  permission :main, { :main => [:index] }, :public => true
  menu :project_menu, :main, { :controller => 'main', :action => 'index' }, :param => :project_id, :caption => "ドキュメントの生成"
end
