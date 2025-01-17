function action(obj)
    % 提取数据
    structures = obj.OutputObj.StructureList;
    sheet_Coordination = [];
    sheet_LayerRange = {};
    sheet_LayerStructure = struct;
    count_start = 0;
    count_end = 0;
    for i=1:length(structures)
        structure = structures{i};
        lines = structure.Line;
        count_start = count_end + 1;
        count_end = count_end + length(lines);
        ipoints = [lines.IPoint];
        jpoints = [lines.JPoint];
        x_ipoints = [ipoints.X];
        y_ipoints = [ipoints.Y];
        z_ipoints = [ipoints.Z];
        x_jpoints = [jpoints.X];
        y_jpoints = [jpoints.Y];
        z_jpoints = [jpoints.Z];
        sheet_Coordination = [sheet_Coordination;...
                             x_ipoints',y_ipoints',z_ipoints',x_jpoints',y_jpoints',z_jpoints'];
        sheet_LayerRange = [sheet_LayerRange;...
                            {structure.Name,count_start,count_end}];
        if isfield(sheet_LayerStructure,class(structure))
            sheet_LayerStructure.(class(structure)) = [sheet_LayerStructure.(class(structure)),structure.Name];
        else
            sheet_LayerStructure.(class(structure)) = {class(structure),structure.Name};
        end
    end
    obj.LayerInformation.Cooridination = sheet_Coordination;
    obj.LayerInformation.LayerRange = sheet_LayerRange;
    obj.LayerInformation.LayerStructure = sheet_LayerStructure;

    % 写出数据到xls文件
    path_xls_file = fullfile(obj.Path_Output,'LayerInformation.xls');
    writematrix(sheet_Coordination,path_xls_file,'Sheet','Coordination');
    writecell(sheet_LayerRange,path_xls_file,"Sheet",'LayerRange');
    names = fieldnames(sheet_LayerStructure);
    for i=1:length(names)
        str_row = sheet_LayerStructure.(names{i});
        writecell(str_row,path_xls_file,"Sheet",'LayerStructure','WriteMode','append');
    end
    % 导出相关的Python文件
    outputInputDataFromExcel(obj);
    outputChangeColor(obj);
    outputObliqueAxonometricDrawing(obj);
end

function outputInputDataFromExcel(obj)
    path_xls = fullfile(obj.Path_Output,'LayerInformation.xls');
    path_xls = strrep(path_xls,'\','\\');
    output_str = ['# -*- coding: utf-8 -*-',newline,...
                    'import rhinoscriptsyntax as rs',newline,...
                    'import sys',newline,...
                    'sys.path.append(r''C:\\ProgramData\\anaconda3\\Lib'')',newline,...
                    'sys.path.append(r''C:\\ProgramData\\anaconda3\\Lib\\site-packages'')',newline,...
                    'sys.path.append(r''C:\\users\\11440\\appdata\\roaming\\python\\python311\\site-packages'')',newline,...
                    'import xlrd',newline,newline,...    
                    '# 打开Excel文件',newline,...
                    sprintf('workbook = xlrd.open_workbook(r''%s'')',path_xls),newline,newline,...    
                    '# 选择工作表',newline,...
                    'sheet_Coord = workbook.sheet_by_name(''Coordination'')',newline,...
                    'sheet_LayerRange = workbook.sheet_by_name(r''LayerRange'')',newline,...
                    'sheet_LayerStructure = workbook.sheet_by_name(r''LayerStructure'')',newline,newline,...    
                    '# 初始化两个空列表来存储起点和终点坐标',newline,...
                    'Coord_StartPoints = []',newline,...
                    'Coord_EndPoints = []',newline,...
                    'for row_index in range(0, sheet_Coord .nrows):',newline,...
                    '    start_point = [sheet_Coord.cell_value(row_index, col_index) for col_index in range(0, 3)]',newline,...
                    '    end_point = [sheet_Coord.cell_value(row_index, col_index) for col_index in range(3, 6)]',newline,...
                    '    Coord_StartPoints.append(start_point)',newline,...
                    '    Coord_EndPoints.append(end_point)',newline,newline,...    
                    '# 将父图层名和子图层名的列表添加到字典中',newline,...
                    'parent_child_dict = {}',newline,...
                    'for row_num in range(sheet_LayerStructure .nrows):',newline,...
                    '    row_values = sheet_LayerStructure .row_values(row_num)',newline,...
                    '    parent_layer = row_values[0]',newline,...
                    '    child_layers = row_values[1:]',newline,...
                    '    child_layers = [child for child in child_layers if child]# 确保子图层名称不为空',newline,...
                    '    parent_child_dict[parent_layer] = child_layers',newline,newline,...    
                    '# 将图层对应范围的列表添加到字典中',newline,...
                    'layer_range_dict = {}',newline,...
                    'for row_num in range(sheet_LayerRange .nrows):',newline,...
                    '    row_values = sheet_LayerRange .row_values(row_num)',newline,...
                    '    name_layer = row_values[0]',newline,...
                    '    start_layers = int(row_values[1])',newline,...
                    '    end_layers = int(row_values[2])',newline,...
                    '    layer_range_dict[name_layer] = [start_layers,end_layers]',newline,newline,...
                    '# 添加父图层',newline,...
                    'for key in parent_child_dict:',newline,...
                    '    rs.AddLayer(key)',newline,newline,...    
                    '# 添加子图层',newline,...
                    'for key in parent_child_dict:',newline,...
                    '    ChildLayers = parent_child_dict[key]',newline,...
                    '    for i in range(0,len(ChildLayers)):',newline,...
                    '        ChildLayer = ChildLayers[i]',newline,...
                    '        rs.AddLayer(ChildLayer,parent=key)',newline,newline,...    
                    '# 生成点对象',newline,...
                    'StartPoints = rs.AddPoints(Coord_StartPoints) # 起点的Geometry对象列表',newline,...
                    'EndPoints = rs.AddPoints(Coord_EndPoints) # 终点的Geometry对象列表',newline,...
                    'Num_Points = len(StartPoints)',newline,...
                    'rs.AddLayer("Point")',newline,...
                    'rs.ObjectLayer(StartPoints,"Point")',newline,...
                    'rs.ObjectLayer(EndPoints,"Point")',newline,newline,...    
                    '# 生成线对象，并存储线对象的位置',newline,...
                    'LineAndIndex = []',newline,...
                    'for i in range(0,Num_Points):',newline,...
                    '    StartPoint = StartPoints[i]',newline,...
                    '    EndPoint = EndPoints[i]',newline,...
                    '    if StartPoint:',newline,...
                    '        if EndPoint: ',newline,...
                    '            id_line = rs.AddLine(StartPoint, EndPoint) # 绘制线对象',newline,...
                    '    LineAndIndex.append([i,id_line])',newline,newline,...    
                    '# 改变线对象的图层',newline,...
                    'for key in layer_range_dict:',newline,...
                    '    range_start = int(layer_range_dict[key][0]-1)',newline,...
                    '    range_end = int(layer_range_dict[key][1]-1)',newline,...
                    '    id_lines = [row[1] for row in LineAndIndex[range_start:range_end+1]]',newline,...
                    '    for id in id_lines:',newline,...
                    '        rs.ObjectLayer(id,key)',newline];
    fileID = fopen(fullfile(obj.Path_Output,'01_InputDataFromExcel.py'),'w');
    fprintf(fileID,output_str);
    fclose(fileID);
end

function outputChangeColor(obj)
    path_xls = fullfile(obj.Path_Output,'LayerInformation.xls');
    path_xls = strrep(path_xls,'\','\\');
    output_str = ['# -*- coding: utf-8 -*-',newline,...
                     'import rhinoscriptsyntax as rs',newline,...
                     '#import xlrd',newline,...
                     'import random',newline,...
                     'from System.Drawing import Color',newline,...
                     '',newline,...
                     '## 导入图层结构信息，将图层结构信息存储在字典中',newline,...
                     sprintf('#workbook = xlrd.open_workbook(r''%s'')',path_xls),newline,...
                     '#sheet_LayerStructure = workbook.sheet_by_name(r''LayerStructure'')',newline,...
                     '#parent_child_dict = {}',newline,...
                     '#for row_num in range(sheet_LayerStructure.nrows):',newline,...
                     '#    row_values = sheet_LayerStructure.row_values(row_num)',newline,...
                     '#    parent_layer = row_values[0]',newline,...
                     '#    child_layers = row_values[1:]',newline,...
                     '#    child_layers = [child for child in child_layers if child]# 确保子图层名称不为空',newline,...
                     '#    parent_child_dict[parent_layer] = child_layers',newline,...
                     '    ',newline,...
                     '',newline,...
                     '',newline,...
                     '# 函数定义：输入父图层名称和RGB值，以改变父图层中所有子图层的颜色',newline,...
                     'def ChangeLayerAttributionByParent(Name_ParentLayer,RGB,Name_LineType="Continuous",LineWidth=0,Recursion=False):',newline,...
                     '    # 选择父图层的所有子图层，并将子图层的名称保存在一个list中',newline,...
                     '#    if Name_ParentLayer in parent_child_dict:',newline,...
                     '#        Name_ChildLayer = parent_child_dict[Name_ParentLayer]',newline,...
                     '#    else:',newline,...
                     '#        Name_ChildLayer = rs.LayerChildren(Name_ParentLayer)',newline,...
                     '    Name_ChildLayer = rs.LayerChildren(Name_ParentLayer)',newline,...
                     '    # 改变所有子图层的信息',newline,...
                     '    color = Color.FromArgb(RGB[0],RGB[1],RGB[2])',newline,...
                     '    # 通过RGB值设置图层颜色',newline,...
                     '    rs.LayerColor(Name_ParentLayer,color)# 改变父图层颜色',newline,...
                     '    rs.LayerLinetype(Name_ParentLayer,Name_LineType)# 改变父图层的线型',newline,...
                     '    rs.LayerPrintWidth(Name_ParentLayer,LineWidth)# 改变父图层的线宽',newline,...
                     '    if Recursion:# 改变父图层下的所有图层（包括子图层的子图层）',newline,...
                     '        if rs.LayerChildCount(Name_ParentLayer)>0:',newline,...
                     '            ChildLayerList = rs.LayerChildren(Name_ParentLayer)',newline,...
                     '            for Name_ChildLayer in ChildLayerList:',newline,...
                     '                ChangeLayerAttributionByParent(Name_ChildLayer,RGB,Name_LineType,LineWidth,True)',newline,...
                     '    else:# 仅改变父图层下一层',newline,...
                     '        for layer in Name_ChildLayer:# 只改变下一级子图层属性',newline,...
                     '            rs.LayerColor(layer,color)',newline,...
                     '            rs.LayerLinetype(layer,Name_LineType)',newline,...
                     '            rs.LayerPrintWidth(layer,LineWidth)',newline,...
                     '',newline,...
                     'def ChangeChildLayerInCurrentLayer(RGB,Name_LineType="Continuous",LineWidth=0,Recursion=False):',newline,...
                     '    Name_Layer = rs.CurrentLayer()',newline,...
                     '    ChangeLayerAttributionByParent(Name_Layer,RGB,Name_LineType,LineWidth,Recursion)',newline,...
                     '',newline,...
                     'def findChildrenLayer(Name_ParentLayer, Name_ChildrenLayer):',newline,...
                     '    if rs.LayerChildCount(Name_ParentLayer) > 0:',newline,...
                     '        ChildLayerList = rs.LayerChildren(Name_ParentLayer)',newline,...
                     '        for Name_ChildLayer in ChildLayerList:',newline,...
                     '            splittedName_ChildLayer = Name_ChildLayer.split(''::'')',newline,...
                     '            if Name_ChildrenLayer in splittedName_ChildLayer:',newline,...
                     '                return Name_ChildLayer',newline,...
                     '            else:',newline,...
                     '                foundLayer = findChildrenLayer(Name_ChildLayer, Name_ChildrenLayer)',newline,...
                     '                if foundLayer:  # 如果在子图层中找到了匹配的图层，返回这个图层的名称',newline,...
                     '                    return foundLayer',newline,...
                     '    else:',newline,...
                     '        return None',newline,...
                     '        ',newline,...
                     'def generate_vivid_rgb():',newline,...
                     '    components = [0, 0, 0]  # 初始化RGB分量',newline,...
                     '    high_component_index = random.randint(0, 2)  # 随机选择一个分量设置为255',newline,...
                     '    components[high_component_index] = 255',newline,...
                     '    # 为其它两个分量生成随机值',newline,...
                     '    for i in range(3):',newline,...
                     '        if i != high_component_index:',newline,...
                     '            components[i] = random.randint(0, 255)',newline,...
                     '    return tuple(components)',newline,...
                     '#配色1',newline,...
                     '#ChangeLayerAttributionByParent("Tower",[117,114,181],"Continuous",0)',newline,...
                     '#ChangeLayerAttributionByParent("Cable",[197,86,89],"Continuous",0)',newline,...
                     '#ChangeLayerAttributionByParent("Girder",[71,120,185],"Continuous",0)',newline,...
                     '#ChangeLayerAttributionByParent("RigidBeam",[203,180,123],"Continuous",0)',newline,...
                     '#ChangeLayerAttributionByParent("Hanger",[84,172,117],"Continuous",0)',newline,...
                     '#ChangeLayerAttributionByParent("StayedCable",[91,183,205],"Continuous",0)',newline,...
                     '',newline,...
                     '#全黑色',newline,...
                     '#ChangeLayerAttributionByParent("Tower",[0,0,0],"Continuous",0)',newline,...
                     '#ChangeLayerAttributionByParent("Cable",[0,0,0],"Continuous",0)',newline,...
                     '#ChangeLayerAttributionByParent("Girder",[0,0,0],"Continuous",0)',newline,...
                     '#ChangeLayerAttributionByParent("RigidBeam",[0,0,0],"Continuous",0)',newline,...
                     '#ChangeLayerAttributionByParent("Hanger",[0,0,0],"Continuous",0)',newline,...
                     '#ChangeLayerAttributionByParent("StayedCable",[0,0,0],"Continuous",0)',newline,...
                     '',newline,...
                     'ChangeLayerAttributionByParent("Bridge2D",[0,0,0],Name_LineType="Continuous",LineWidth=0,Recursion=True)',newline,...
                     '',newline,...
                     'RGB = [[255,0,0],[0,255,0],[0,0,255],[255,255,0],[255,0,255],[0,255,255],',newline,...
                     '       [245,10,10],[10,245,10],[10,10,245],[245,245,10],[245,10,245],[10,245,245]]',newline,...
                     '',newline,...
                     'for i in range(14):',newline,...
                     '    name = ''Girder_''+str(i+1)',newline,...
                     '    layer = findChildrenLayer(''Bridge2D'', name)',newline,...
                     '    random_rgb = random.choice(RGB)',newline,...
                     '    ChangeLayerAttributionByParent(layer,random_rgb,Name_LineType="Continuous",LineWidth=1,Recursion=True)'];
    fileID = fopen(fullfile(obj.Path_Output,'02_ChangeColor.py'),'w');
    fprintf(fileID,output_str);
    fclose(fileID);
end
function outputObliqueAxonometricDrawing(obj)
    output_str = ['# -*- coding: utf-8 -*-',newline,...
                 'import rhinoscriptsyntax as rs',newline,...
                 '',newline,...
                 '# 选取线对象',newline,...
                 'all_objs = rs.AllObjects()',newline,...
                 '#all_objs = rs.GetObjects("选取物体")',newline,...
                 '# 新建参考点ReferencePoint',newline,...
                 'WorldOrigin = rs.AddPoint([0,0,0])',newline,...
                 'rs.AddLayer("ReferencePoint")',newline,...
                 'rs.ObjectLayer(WorldOrigin,"ReferencePoint")',newline,...
                 '# 新建世界xyz方向的单位向量',newline,...
                 'unit_X_Point = rs.AddPoint([1,0,0])',newline,...
                 'unit_Y_Point = rs.AddPoint([0,1,0])',newline,...
                 'unit_Z_Point = rs.AddPoint([0,0,1])',newline,...
                 'rs.ObjectLayer(unit_X_Point,"ReferencePoint")',newline,...
                 'rs.ObjectLayer(unit_Y_Point,"ReferencePoint")',newline,...
                 'rs.ObjectLayer(unit_Z_Point,"ReferencePoint")',newline,...
                 'unit_X_Vector = rs.VectorCreate(unit_X_Point,WorldOrigin)',newline,...
                 'unit_Y_Vector = rs.VectorCreate(unit_Y_Point,WorldOrigin)',newline,...
                 'unit_Z_Vector = rs.VectorCreate(unit_Z_Point,WorldOrigin)',newline,...
                 '# 设定Shear基点和参考点',newline,...
                 'Shear_Origin_Point = WorldOrigin',newline,...
                 'Shear_Reference_Point = unit_Y_Vector',newline,...
                 '# Y轴方向变为原来的0.5倍',newline,...
                 'rs.ScaleObjects(all_objs,Shear_Origin_Point,[1,0.5,1])',newline,...
                 '# 先沿着Y轴旋转45°',newline,...
                 'rotated_objs = rs.RotateObjects(all_objs,WorldOrigin,45,axis=unit_Y_Vector)',newline,...
                 '# Shear',newline,...
                 'sheared_objs = rs.ShearObjects(rotated_objs,Shear_Origin_Point,Shear_Reference_Point,45)',newline,...
                 '# 沿着Y轴旋转-45°',newline,...
                 'ObliqueAxonometric_objs = rs.RotateObjects(sheared_objs,WorldOrigin,-45,axis=unit_Y_Vector)',newline,...
                 '# Make2D拍平'];
    fileID = fopen(fullfile(obj.Path_Output,'03_ObliqueAxonometricDrawing.py'),'w');
    fprintf(fileID,output_str);
    fclose(fileID);
end