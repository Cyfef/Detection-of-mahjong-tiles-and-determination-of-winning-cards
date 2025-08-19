function is_win = mahjong_win_check(tiles)
% 输入: tiles - 元胞数组，如 {'1m','2m',...,'Z'}

% 解析牌型并验证合法性
[counts, valid] = parse_tiles(tiles);
% 若牌数不合法或总牌数不为14，直接返回false
if ~valid || sum([sum(counts.m), sum(counts.s), sum(counts.p), counts.z]) ~= 14
    is_win = false;
    return;
end

%% 七小对检查
% 若满足七小对，直接返回true
if check_seven_pairs(counts)
    is_win = true;
    return;
end

%% 断幺九规则检查
% 红中(Z)少于2个时，必须含有1或9
if counts.z < 2
    has19 = any([counts.m(1), counts.m(9), counts.s(1), counts.s(9), counts.p(1), counts.p(9)]);
    if ~has19  % 若无1/9，则不满足断幺九，返回false
        is_win = false;
        return;
    end
end

%% 清一色检查
if check_qing_yi_se(counts)
    is_win = true;
    return;
end

%% 飘胡检查
if check_piao(counts)
    is_win = true;
    return;
end

%% 常规胡牌检查
if check_regular_win(counts)
    is_win = true;
else
    is_win = false;
end
end

%%%%% ======= 内部函数 ======= %%%%%

function [counts, valid] = parse_tiles(tiles)
    % parse_tiles 解析输入的牌面数组，返回计数结构与合法性
    counts = struct('m',zeros(1,9), 's',zeros(1,9), 'p',zeros(1,9), 'z',0);
    valid = true;
    for i = 1:numel(tiles)
        t = tiles{i};
        if strcmp(t,'Z')  % 红中
            counts.z = counts.z + 1;
        else
            if numel(t)~=2  % 格式应为"数字+花色"
                valid = false; return;
            end
            num = str2double(t(1));  % 数值部分
            suit = t(2);             % 花色部分
            if isnan(num) || num<1 || num>9  % 数值范围检查
                valid = false; return;
            end
            switch suit
                case 'm'
                    counts.m(num) = counts.m(num) + 1;  % 万
                case 's'
                    counts.s(num) = counts.s(num) + 1;  % 条
                case 'p'
                    counts.p(num) = counts.p(num) + 1;  % 筒
                otherwise  % 非法花色
                    valid = false; return;
            end
        end
    end
end

function is7 = check_seven_pairs(counts)
    % check_seven_pairs 检查是否为七小对
    % 红中需成对
    if mod(counts.z,2)~=0
        is7 = false; return;
    end
    total_pairs = counts.z/2;
    for suit = {'m','s','p'}  % 遍历三种花色
        cur = counts.(suit{1});
        for n = 1:9
            if mod(cur(n),2)~=0  % 若有单张则非七小对
                is7 = false; return;
            end
            total_pairs = total_pairs + cur(n)/2;
        end
    end
    is7 = (total_pairs==7);  % 对数是否为7
end

function is_piao = check_piao(counts)
    % check_piao 检查飘胡
    if counts.z~=2
        is_piao = false; return;
    end
    for suit = {'m','s','p'}
        cur = counts.(suit{1});
        if any(mod(cur,3)~=0)  
            is_piao = false; return;
        end
    end
    is_piao = true;
end

function is_qys = check_qing_yi_se(counts)
    non_zero_suits = [any(counts.m), any(counts.s), any(counts.p)];
    is_qys = (sum(non_zero_suits)==1) && counts.z==0;
end

function is_win = check_regular_win(counts)
    tiles = generate_all_tiles();
    for i = 1:numel(tiles)
        nc = copy_counts(counts);                  % 深拷贝计数
        [ok, nc] = try_remove_pair(nc, tiles{i}); % 去掉一对
        if ok && check_remaining(nc)              % 若剩余能全拆
            is_win = true;
            return;
        end
    end
    is_win = false;
end

function all_tiles = generate_all_tiles()
    % generate_all_tiles 列出所有34种可能的牌
    all_tiles = cell(1,28);
    idx = 1;
    for n = 1:9, all_tiles{idx}=sprintf('%dm',n); idx=idx+1; end
    for n = 1:9, all_tiles{idx}=sprintf('%ds',n); idx=idx+1; end
    for n = 1:9, all_tiles{idx}=sprintf('%dp',n); idx=idx+1; end
    all_tiles{28} = 'Z';  % 红中
end

function nc = copy_counts(oc)
    % copy_counts 复制计数结构体
    nc = struct('m',oc.m, 's',oc.s, 'p',oc.p, 'z',oc.z);
end

function [ok, counts] = try_remove_pair(counts, tile)
    % try_remove_pair 尝试移除一对
    ok = false;
    if strcmp(tile,'Z')
        if counts.z>=2
            counts.z = counts.z - 2;
            ok = true;
        end
    else
        num = str2double(tile(1));
        suit = tile(2);
        if counts.(suit)(num) >= 2
            counts.(suit)(num) = counts.(suit)(num) - 2;
            ok = true;
        end
    end
end

function ok = check_remaining(counts)
    % check_remaining 检查剩余牌能否全拆
    for suit = {'m','s','p'}
        if ~can_form_sets(counts.(suit{1}))
            ok = false;
            return;
        end
    end
    ok = true;
end

function ok = can_form_sets(arr)
    % can_form_sets 递归判断能否拆分
    if sum(arr)==0  % 递归终止：无牌剩余
        ok = true;
        return;
    end
    % 尝试列
    for i = 1:7
        if arr(i)>=1 && arr(i+1)>=1 && arr(i+2)>=1
            new_arr = arr;
            new_arr(i:i+2) = new_arr(i:i+2) - 1;
            if can_form_sets(new_arr)
                ok = true;
                return;
            end
        end
    end
    % 尝试差
    for i = 1:9
        if arr(i)>=3
            new_arr = arr;
            new_arr(i) = new_arr(i) - 3;
            if can_form_sets(new_arr)
                ok = true;
                return;
            end
        end
    end
    ok = false;  % 都不行则返回false
end
