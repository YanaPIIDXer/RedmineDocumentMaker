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

        # マイルストーンページ生成
        def makeMilestonePage
            @pdf.AddPage('L', 'A4')

            # 表題
            writeText(@pdf.getPageWidth / 2, 10, "実装機能", 32)

            x = 50
            y = 30

            # ↓これだとソートが機能しない。
            #milestones = @project.versions.order("created_on")
            milestones = Version.where("project_id = ?", @project.id).order("effective_date, created_on")
            if milestones.count == 0
                # マイルストーンが設定されていない場合は機能のみを書き出す。
                functions = Issue.where("project_id = ? and parent_id is null", @project.id)
                writeFunctions(functions, x, y, 30)
                return
            end

            # マイルストーンとそこで実装する機能の列挙
            milestones.each do |milestone|
                # マイルストーン
                writeText(x, y, milestone.name, 30, false)
                y += @pdf.getFontSize() + 5

                functions = Issue.where("project_id = ? and fixed_version_id = ? and parent_id is null", @project.id, milestone.id)
                y = writeFunctions(functions, x + 20, y, 20)
            end
        end
        
        # 生成
        def generate           
            return @pdf.output()
        end
        
private

        # 表題ページ作成
        def makeTitlePage
            # ↓ページと枠生成の処理を別メソッドに抽出したいんだけど、
            #  そのリファクタリングを行うだけで処理がイカれる。
            #  （しかも、色々弄ってる内にAddPageの引数決め打ちでもイカれ始めると言う謎挙動。）
            @pdf.AddPage('L' 'A10')

            # 枠
            @pdf.SetFillColor(255, 255, 255)
            @pdf.SetDrawColor(0, 0, 0)
            width = @pdf.getPageWidth() - 20
            height = @pdf.getPageHeight() - 20
            @pdf.rect(10, 10, width, height, 'DF')

            # 表題
            x = width * 0.5
            y = height * 0.5
            writeText(x, y, "#{@project.name}", 64)

            y += @pdf.getFontSize()
            writeText(x, y, "ドキュメント", 64)
        end

        # 機能を書き出す
        # functions: 機能リスト
        # x: X座標
        # startY: 書き始めるY座標
        # fontSize: 文字サイズ
        # returns: 書き終わったY座標
        def writeFunctions(functions, x, startY, fontSize)
            y = startY
            functions.each do |function|
                writeText(x, y, "・#{function.subject}", fontSize, false)
                y += @pdf.getFontSize() + 3
            end
            return y
        end

        # 文字列書き込み
        # x: X座標
        # y: Y座標
        # text: 文字列
        def writeText(x, y, text, size = 22, centering=true)
            @pdf.SetFontSize(size)

            # 中心に持ってくる。
            if centering
                x -= @pdf.getFontSize() * (text.length / 2)
            end
            
            @pdf.SetXY(x, y)
            @pdf.write(5, text, '')
        end

    end
    
end
