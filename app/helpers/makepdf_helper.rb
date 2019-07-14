module MakepdfHelper

    # ガントチャート用オブジェクト
    # マイルストーン、タスクを表す。
    class GanttObject
        attr_reader :name, :startDate, :endDate, :isMilestone

        # コンストラクタ
        def initialize(name, startDate, endDate, isMilestone)
            @name = name
            @startDate = startDate
            @endDate = endDate
            @isMilestone = isMilestone
        end
        
        # 生成
        # project: プロジェクト
        # returns: オブジェクト配列
        def self.generate(project)
            objects = []
            
            milestones = Version.where("project_id = ?", project.id).order("effective_date, created_on")
            if milestones.count == 0
                # マイルストーンが無い場合は機能をそのまま列挙。
                functions = Issue.where("project_id = ? and parent_id is null", project.id) 
                appendFunctions(functions, objects)
                return objects
            end

            milestones.each do |milestone|
                # マイルストーンを追加。
                #obj = GanttObject.new(milestone.name, milestone.start_date, milestone.due_date, true)
                # ↑実はmilestone.due_dateには値が入っていない。

                # マイルストーンの機能を列挙。
                functions = Issue.where("project_id = ? and fixed_version_id = ? and parent_id is null", project.id, milestone.id)

                # 終了日を出す。
                endDate = functions.maximum("due_date")

                # データを追加する。
                obj = GanttObject.new(milestone.name, milestone.start_date, endDate, true)
                objects.push(obj)
                appendFunctions(functions, objects)
            end

            return objects
        end

private

        # 機能を列挙
        # functions: 機能リスト
        # outObjects: 配列
        def self.appendFunctions(functions, outObjects)
            functions.each do |function|
                obj = GanttObject.new(function.subject, function.start_date, function.due_date, false)
                outObjects.push(obj)
            end
        end

    end

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
            makeNewPage()

            # 表題
            writeText(@pdf.getPageWidth() / 2, 10, "実装機能", 32)

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

        # 条件掲示ページ生成
        # desiredReward: 希望報酬額
        def makeConditionNoticePage(desiredReward)
            makeNewPage()

            # 表題
            writeText(@pdf.getPageWidth() / 2, 10, "条件掲示", 32)

            y = 50
            
            # 作業開始日
            startDate = @project.start_date
            if startDate
                writeText(80, y, "作業開始日：#{startDate.strftime("%Y年%-m月%-d日")}", 27, false)
                y += 30
            end

            # 作業完了日
            endDate = @project.due_date
            if endDate
                writeText(80, y, "作業終了日：#{endDate.strftime("%Y年%-m月%-d日")}", 27, false)       
                y += 30
            end

            # 希望報酬額
            writeText(80, y, "希望報酬額：￥#{desiredReward.to_i.to_s(:delimited)}円", 27, false)
        end

        # ガントチャートページ生成
        def makeGanttChartPage
            startDate = @project.start_date
            endDate = @project.due_date

            # 開始日 or 終了日が決まっていない場合は生成しない。
            if !startDate || !endDate
                return
            end

            makeNewPage()

            # 表題
            writeText(@pdf.getPageWidth() / 2, 10, "作業予定", 32)
            
            # ガントチャート
            dayCount = (((endDate - startDate).day / 86400) + 1).to_i   
            cellSize = (@pdf.getPageWidth() - 40 - 60) / dayCount

            # 月日表示
            y = 30
            currentMonth = startDate.month
            endMonth = endDate.month
            monthCount = endMonth - currentMonth + 1
            x = 80
            currentDay = startDate.day
            year = startDate.year
            currentMonth.step(endMonth, 1){|month|
                endDay = Date.new(year, month, -1).day
                if month == endMonth
                    endDay = endDate.day
                end
                
                @pdf.SetFillColor(255, 255, 255)
                @pdf.SetDrawColor(0, 0, 0)
                
                # 月
                size = cellSize * (endDay - currentDay + 1)
                @pdf.rect(x, y, size, cellSize, 'DF')
                writeText(x + (size / 2), y + (cellSize / 2) - 3, "#{month}", 10, false)

                # 日
                i = 0
                currentDay.step(endDay, 1){|day|
                    setWeekColor(Date.new(year, month, day))
                    @pdf.rect(x + (i * cellSize), y + cellSize, cellSize, cellSize, 'DF')
                    writeText(x + (i * cellSize) + 3, y + cellSize + (cellSize / 2) - 3, "#{day}", 10, false)
                    i = i + 1
                }

                x += size
                currentDay = 1
                if month == 12
                    year = year + 1
                end
            }

            y += cellSize * 2

            # 作業日
            ganttObjs = GanttObject.generate(@project)
            ganttObjs.each do |obj|
                # タスク名
                if obj.isMilestone
                    @pdf.SetFillColor(0, 128, 128)
                else
                    @pdf.SetFillColor(255, 255, 255)
                end
                @pdf.SetDrawColor(0, 0, 0)
                @pdf.rect(20, y, 60, cellSize, 'DF')
                writeText(40, y + (cellSize / 2) - 3, obj.name, 10, false)

                date = startDate
                
                # 作業予定日
                dayCount.times do |i|
                    # 色付け
                    if date >= obj.startDate && date <= obj.endDate
                        if obj.isMilestone
                            @pdf.SetFillColor(0, 255, 255)
                        else
                            @pdf.SetFillColor(0, 0, 255)
                        end
                    else
                        setWeekColor(date)
                    end
                    
                    @pdf.rect(80 + (cellSize * i), y, cellSize, cellSize, 'DF')

                    date += 1
                end
                
                y += cellSize
            end
        end
        
        # 生成
        def generate           
            return @pdf.output()
        end
        
private

        # 表題ページ作成
        def makeTitlePage
            makeNewPage()

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
            writeText(x, y, "契約要求", 64)
        end

        # 新規ページ生成
        # @pdf.AddPageを直接叩くのではなく、このメソッドを経由する事。
        def makeNewPage
            @pdf.AddPage('L' 'A10')
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

        # 曜日の色をセット
        # date: 日付
        def setWeekColor(date)
            if date.sunday?
                # 日曜日
                @pdf.SetFillColor(255, 0, 0)
            elsif date.saturday?
                # 土曜日
                @pdf.SetFillColor(0, 0, 255)
            else
                # 平日
                @pdf.SetFillColor(255, 255, 255) 
            end
        end

    end
    
end
