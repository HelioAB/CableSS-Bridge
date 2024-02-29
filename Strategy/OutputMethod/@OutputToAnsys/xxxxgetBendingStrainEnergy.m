function ResultFilePath = xxxxgetBendingStrainEnergy(obj,StructureList,DataBasePath)% 本方法已废弃，见Element.getBendingStrainEnergy
    % 新建文件夹，以容纳导出的数据
    new_folder = [obj.WorkPath,'\Data_BendingStrainEnergy'];
    obj.PostProcessingPath.BendingStrainEnergyData = new_folder;
    try 
        [status,msg,msgID] = mkdir(new_folder);
    catch ME % 忽略"文件已经存在"的警告信息
        switch ME.identifier
            case 'MATLAB:MKDIR:DirectoryExists'
            otherwise
                rethrow(ME)
        end
    end
    % 参数处理
    Map_MatlabLine2AnsysElem = obj.OutputObj.Params.Map_MatlabLine2AnsysElem;
    datafile_name = cellfun(@(x) {x.Name},StructureList);
    ResultFilePath = cell(size(StructureList));
    [Dir_DataBase,FileName_DataBase,FileExt_DataBase] = convertPath(DataBasePath);
    % 输出到APDL file的 output_str
    output_str = ['finish $ /clear',newline,...
                  '/post1',newline,...
                  sprintf('resume,%s,%s',[Dir_DataBase,FileName_DataBase],FileExt_DataBase),newline,newline,...
                  '! 导出弯曲应变能所需要的参数',newline];
    for i=1:length(StructureList)
        structure = StructureList{i};
        output_str = [output_str,getBendingStrainEnergy_Structure(obj,structure,Map_MatlabLine2AnsysElem,datafile_name{i})];
        ResultFilePath{i} = [new_folder,'\',datafile_name{i},'.txt'];
    end
    % 输出到APDL file
    APDLFilePath = [new_folder,'\getBendingStrainEnergy.mac'];
    assignin("base","APDLFilePath",APDLFilePath)
    assignin("base","output_str",output_str)
    obj.outputAPDL(output_str,APDLFilePath,'w')
    % 运行APDL file
    obj.runMac('MacFilePath',APDLFilePath,'WorkPath',new_folder)
end
function output_str = getBendingStrainEnergy_Structure(obj,structure,Map_MatlabLine2AnsysElem,outputfile_name)
    output_str = [sprintf('! %s',structure.Name),newline];
    line = structure.Line;
    all_elem_num = [];
    for i=1:length(line)
        num_elem = Map_MatlabLine2AnsysElem(line(i).Num);
        all_elem_num = [all_elem_num,num_elem];
    end
    output_str = [output_str,sprintf('count_num = %d',length(all_elem_num)),newline];
    output_str = [output_str,'*del,ElemNumArray,,NoPr',newline,obj.outputArray(all_elem_num,'ElemNumArray')];
    output_str = [output_str,['*del,elem_output,,NoPr',newline,...
                                    '*dim,elem_output,array,count_num,11'],newline,...
                                    '*do,i,1,count_num',newline,...
                                    '   num_elem = ElemNumArray(i)',newline,...
                                    '   elem_output(i,1) = num_elem',newline,...
                                    '   *Get,num_mat,Elem,num_elem,Attr,Mat',newline,...
                                    '   *Get,elem_output(i,2),Ex,num_mat ! 弹模',newline,...
                                    '   *Get,num_sec,Elem,num_elem,Attr,SecN',newline,...
                                    '   *Get,elem_output(i,3),SecP,num_sec,Prop,Iyy ! Iyy',newline,...
                                    '   *Get,elem_output(i,4),SecP,num_sec,Prop,Izz ! Izz',newline,...
                                    '   *Get,num_real,Elem,num_elem,Attr,Real',newline,...
                                    '   *Get,elem_output(i,5),RCon,num_real,Const,3 ! Iyy',newline,...
                                    '   *Get,elem_output(i,6),RCon,num_real,Const,2 ! Izz',newline,...
                                    '   *Get,elem_output(i,7),Elem,num_elem,Leng ! 单元长度',newline,...
                                    '   *Get,elem_output(i,8),Elem,num_elem,Smisc,2 ! Myi',newline,...
                                    '   *Get,elem_output(i,9),Elem,num_elem,Smisc,3 ! Mzi',newline,...
                                    '   *Get,elem_output(i,10),Elem,num_elem,Smisc,15 ! Myj',newline,...
                                    '   *Get,elem_output(i,11),Elem,num_elem,Smisc,16 ! Mzj',newline,...
                                    '*enddo',newline]; % 获取数据，存储到ElemNumArray中
    output_str = [output_str,sprintf('*cfopen,%s,txt ! 导出到%s.txt文件中',outputfile_name,outputfile_name),newline,...
                                    '*vwrite,elem_output(1,1),elem_output(1,2),elem_output(1,3),elem_output(1,4),elem_output(1,5),',...
                                    'elem_output(1,6),elem_output(1,7),elem_output(1,8),elem_output(1,9),elem_output(1,10),elem_output(1,11)',newline,...
                                    '%%20I%%20.8e%%20.8e%%20.8e%%20.8e%%20.8e%%20.8e%%20.8e%%20.8e%%20.8e%%20.8e',newline,...
                                    '*cfclos',newline,newline];

end
function [dir,file_name,file_extension] = convertPath(path)
    splited_path = split(path,'\');
    splited_path = splited_path';
    file = split(splited_path{end},'.');
    file_name = file{1};
    file_extension = file{2};
    joined_dir = join(splited_path(1:end-1),'\\');
    dir = [joined_dir{:},'\\'];
end