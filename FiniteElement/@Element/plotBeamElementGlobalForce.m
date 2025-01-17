function [fig,ax] = plotBeamElementGlobalForce(obj,ANodes_matrix,BNodes_matrix,InternalForce_A_matrix,InternalForce_B_matrix,type_elems,type_force,options)
    % 输入参数ANodes、BNodes、InternalForce_A、InternalForce_B 由obj.getBeamElementGlobalForce()提供
    arguments
        obj % 每一行：一个结构参数的Element; 不同行: 不同结构参数的Element
        ANodes_matrix
        BNodes_matrix
        InternalForce_A_matrix
        InternalForce_B_matrix
        type_elems {mustBeMember(type_elems,{'Girder','Tower'})}
        type_force {mustBeMember(type_force,{'Fx','My'})}
        options.ParametersValue (1,:) {mustBeNumeric} = []
        options.ParametersName {mustBeText} = ''
        options.Pattern {mustBeMember(options.Pattern,{'bar','plot3'})} = 'plot3'
        options.Figure = figure
        options.Axis = axes
        options.ForceName = ''
        options.ColorMap = 'jet'
        options.Title = ''
        options.Scale = 1
        options.Tick = []
        options.TickLabel = ''
        options.Unit = ''
    end
    sz = size(ANodes_matrix);
    if ~(all(size(BNodes_matrix)==sz) && all(size(InternalForce_A_matrix)==sz) && all(size(InternalForce_B_matrix)==sz))
        error('输入的ANodes_matrix、BNodes_matrix、InternalForce_A_matrix、InternalForce_B_matrix应该有相同的size')
    end
    %
    fig = options.Figure;
    ax = options.Axis;
    hold(ax,'on')
    figure(fig);
    %
    switch type_elems
        case 'Girder'
            type_elems_zh = '加劲梁';
        case 'Tower'
            type_elems_zh = '桥塔';
    end
    %
    switch type_force
        case 'Fx'
            type_force_zh = '轴力';
        case 'My'
            type_force_zh = '弯矩';
    end
    %
    if isempty(options.ParametersName)
        options.ParametersName = '';
    end
    if isempty(options.Title)
        options.Title = sprintf([options.ParametersName,' ',type_elems_zh,type_force_zh,'(%s)'],options.Unit);
    end
    %
    if isempty(options.ParametersValue)
        cell_legend = {'<Value>'};
    else
        cell_legend = cell(1,sz(1));
        for i=1:sz(1)
            cell_legend{i} = num2str(options.ParametersValue(i),'%.4f');
        end
    end
    %
    if ~isempty(options.ParametersValue) && length(options.ParametersValue) >= 2
        interpolated_cmap = interpolateColor(options.ParametersValue,options.ColorMap);
    else
        interpolated_cmap = [1,0,0];
    end
    %
    max_InternalForce = max([InternalForce_A_matrix;InternalForce_B_matrix],[],'all');
    min_InternalForce = min([InternalForce_A_matrix;InternalForce_B_matrix],[],'all');
    
    allNodes = [ANodes_matrix;BNodes_matrix];
    max_X_Nodes = max([allNodes.X],[],'all');
    min_X_Nodes = min([allNodes.X],[],'all');
    max_Y_Nodes = max([allNodes.Y],[],'all');
    min_Y_Nodes = min([allNodes.Y],[],'all');
    max_Z_Nodes = max([allNodes.Z],[],'all');
    min_Z_Nodes = min([allNodes.Z],[],'all');
    %
    for row = 1:sz(1)
        ANodes = ANodes_matrix(row,:);
        BNodes = BNodes_matrix(row,:);
        InternalForce_A = InternalForce_A_matrix(row,:); % 每一行对应一个Node；不同行代表不同结构参数的结果
        InternalForce_B = InternalForce_B_matrix(row,:);
        color = interpolated_cmap(row,:);
        switch options.Pattern
            case 'bar'
                error('暂不支持使用bar来作图')
            case 'plot3'
                len = length(InternalForce_A);
                PostionX = zeros(1,2*len);
                PostionY = zeros(1,2*len);
                PostionZ = zeros(1,2*len);
                if strcmp(type_elems,'Girder')
                    PostionX(1:2:end) = [ANodes.X];
                    PostionX(2:2:end) = [BNodes.X];
                    PostionZ(1:2:end) = [ANodes.Z] + options.Scale*InternalForce_A;
                    PostionZ(2:2:end) = [BNodes.Z] + options.Scale*InternalForce_B;
                    plot3(ax,PostionX,PostionY,PostionZ,'Color',color,'LineWidth',1);
                    ax.ZGrid = 'on';
                    ax.XAxis.Label.String = '位置(m)';
                    ax.ZAxis.Label.String = options.ForceName;
                    if ~isempty(options.Tick)
                        ax.ZTick = options.Tick;
                    end
                    if ~isempty(options.TickLabel)
                        ax.ZTickLabel = options.TickLabel;
                    end
                    ax.XMinorTick = 'on';
                    ax.XLim = [min_X_Nodes,max_X_Nodes];
                    assignin("base","min_InternalForce",min_InternalForce)
                    assignin("base","max_InternalForce",max_InternalForce)
                    ax.ZLim = [min_InternalForce,max_InternalForce];
    
                elseif strcmp(type_elems,'Tower')
                    PostionX(1:2:end) = [ANodes.X] + options.Scale*InternalForce_A;
                    PostionX(2:2:end) = [BNodes.X] + options.Scale*InternalForce_B;
                    PostionZ(1:2:end) = [ANodes.Z];
                    PostionZ(2:2:end) = [BNodes.Z];
                    plot3(ax,PostionX,PostionY,PostionZ,'Color',color,'LineWidth',1);
                    ax.XGrid = 'on';
                    ax.XAxis.Label.String = options.ForceName;
                    ax.ZAxis.Label.String = '塔高(m)';
                    options.Tick
                    options.TickLabel
                    if ~isempty(options.Tick)
                        ax.XTick = options.Tick;
                    end
                    if ~isempty(options.TickLabel)
                        ax.XTickLabel = options.TickLabel;
                    end
                    ax.ZMinorTick = 'on';
                    ax.XLim = [min_InternalForce,max_InternalForce];
                    ax.ZLim = [min_Z_Nodes,max_Z_Nodes];
    
                end
        end

    end

    view([0,-1,0]);
    ax.FontName = 'Times New Roman + SimSun';
    ax.TickLabelInterpreter = 'tex';
    ax.GridLineStyle = ':';
    ax.GridLineWidth = 1;
    ax.TickDir = 'out';
    ax.Title.String = options.Title;
    legend(ax,cell_legend,'Location','best');
    
end
function interpolated_cmap = interpolateColor(data,map)
    arguments
        data
        map = 'jet'
    end
    % 确定数据的最小值和最大值
    data_min = min(data);
    data_max = max(data);
    
    cmap = colormap(map);
    % 将数据归一化到[0, 1]的范围
    normalized_data = (data - data_min) / (data_max - data_min);
    
    % 使用interp1进行插值
    cmap_size = size(cmap, 1); % 获取colormap的大小
    interpolated_cmap = zeros(length(data),3); % 初始化颜色矩阵，大小与数据相同
    for i = 1:length(data)
        % 对于每个数据点，找到对应的颜色
        cmap_index = normalized_data(i) * (cmap_size - 1) + 1;
        interpolated_cmap(i,:) = interp1(1:cmap_size, cmap, cmap_index);
    end
end