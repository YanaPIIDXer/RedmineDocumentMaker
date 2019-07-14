module MakepdfHelper

    # PDF作成クラス
    # PDFの作り方・・・と言うか、PDFクラスについての情報は以下を参照。
    # https://github.com/naitoh/rbpdf/
    class PDFMaker

        # コンストラクタ
        # project: プロジェクトModel
        def initialize(project)
            @pdf = ::Redmine::Export::PDF::ITCPDF::new('ja')
            @project = project

            @pdf.SetTitle("#{@project.name} ドキュメント")
            @pdf.set_margins(15, 27, 15)
            
            makeTitlePage()
        end

        # 生成
        def generate           
            return @pdf.output()
        end
        
private

        # 表題ページ作成
        def makeTitlePage
            @pdf.AddPage('L' 'A10')

            # 枠
            @pdf.SetFillColor(255, 255, 255)
            @pdf.SetDrawColor(0, 0, 0)
            width = @pdf.getPageWidth() - 20
            height = @pdf.getPageHeight() - 20
            @pdf.rect(10, 10, width, height, 'DF')

            # 表題
            @pdf.SetFontSize(64)
            
            x = width * 0.5
            y = height * 0.5
            writeText(x, y, "#{@project.name}")

            y += @pdf.getFontSize()
            writeText(x, y, "ドキュメント")
        end

        # 文字列書き込み
        # x: X座標
        # y: Y座標
        # text: 文字列
        def writeText(x, y, text)
            # 中心に持ってくる。
            x -= @pdf.getFontSize() * (text.length / 2)
            
            @pdf.SetXY(x, y)
            @pdf.write(5, text, '')
        end

    end
    
end
