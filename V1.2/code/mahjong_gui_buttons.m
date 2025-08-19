function mahjong_gui_buttons
    f = figure('Name','麻将胡牌判定（按钮版）', 'Position',[200 100 800 450]);

    % 显示当前输入
    uicontrol('Style','text', 'Position',[20 400 100 20], ...
        'String','当前输入：', 'HorizontalAlignment','left');
    hDisplay = uicontrol('Style','edit', 'Position',[120 395 640 25], ...
        'String','', 'Enable','inactive');

    % 全局牌列表
    tileList = {};

    % 所有牌按钮排布参数
    suits = {'m','s','p'};
    startX = 20;
    startY = 340;
    tileWidth = 40;
    tileHeight = 30;
    gap = 5;

    for i = 1:3 % 每个花色一行
        for n = 1:9
            tile = sprintf('%d%s', n, suits{i});
            x = startX + (n-1)*(tileWidth + gap);
            y = startY - (i-1)*(tileHeight + gap);
            uicontrol('Style','pushbutton', 'Position',[x y tileWidth tileHeight], ...
                'String',tile, 'Callback',@(src,~)addTile(tile));
        end
    end

    % 红中按钮 + 撤销清空
    uicontrol('Style','pushbutton', 'Position',[startX startY - 3*(tileHeight+gap) tileWidth+20 tileHeight], ...
        'String','Z (红中)', 'Callback',@(src,~)addTile('Z'));

    uicontrol('Style','pushbutton', 'Position',[startX + 100 startY - 3*(tileHeight+gap) tileWidth+20 tileHeight], ...
        'String','撤销', 'Callback',@undoTile);
    uicontrol('Style','pushbutton', 'Position',[startX + 180 startY - 3*(tileHeight+gap) tileWidth+20 tileHeight], ...
        'String','清空', 'Callback',@clearTiles);

    % 判断胡牌按钮
    uicontrol('Style','pushbutton', 'Position',[startX + 270 startY - 3*(tileHeight+gap) 120 tileHeight], ...
        'String','判断是否胡牌', 'FontWeight','bold', 'Callback',@checkHu);

    % 结果显示
    hResult = uicontrol('Style','text', 'Position',[startX + 410 startY - 3*(tileHeight+gap) 200 tileHeight+10], ...
        'String','', 'FontSize',12);

    % --------- 回调函数定义 ---------
    function addTile(tile)
        if numel(tileList) >= 14
            return;
        end
        tileList{end+1} = tile;
        updateDisplay();
    end

    function undoTile(~,~)
        if ~isempty(tileList)
            tileList(end) = [];
            updateDisplay();
        end
    end

    function clearTiles(~,~)
        tileList = {};
        updateDisplay();
    end

    function updateDisplay()
        set(hDisplay, 'String', strjoin(tileList, ' '));
    end

    function checkHu(~,~)
        if numel(tileList) ~= 14
            set(hResult, 'String','⚠️ 请输入14张牌');
            return;
        end
        try
            is_win = mahjong_win_check(tileList);
            if is_win
                set(hResult, 'String','✅ 胡了！');
            else
                set(hResult, 'String','❌ 没胡。');
            end
        catch
            set(hResult, 'String','⚠️ 判断出错');
        end
    end
end