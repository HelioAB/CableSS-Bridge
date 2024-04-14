function [Ux,Uy,Uz] = getDisplacement(obj,points,name_DataBase)
    arguments
        obj
        points
        name_DataBase {mustBeText} = strcat(obj.JobName,'Result')
    end
    OutputMethod_clone = obj.clone();
    % 让ANSYS导出数据的宏文件
    num_points = [points.Num];
    count_points = length(num_points);
    str_num_keypoints = OutputMethod_clone.outputArray(num_points,'num_keypoints');
    output_str = ['/post1',newline,...
                sprintf('resume,%s,db',name_DataBase),newline,...
                'set,1,last',newline,newline,...
                sprintf('count_keypoints = %d',count_points),newline,...
                str_num_keypoints,newline,...
                '*dim,Displacement_x,array,count_keypoints',newline,...
                '*dim,Displacement_y,array,count_keypoints',newline,...
                '*dim,Displacement_z,array,count_keypoints',newline,newline,...
                '! 提取keypoint对应node上的位移值',newline,...
                'allsel',newline,...
                '*do,i,1,count_keypoints,1',newline,...
                '    ksel,s,,,num_keypoints(i) $ nslk,s $ *get,num_node,node,0,num,max! 获取节点编号',newline,...
                '    *get,Displacement_x(i),Node,num_node,U,x',newline,...
                '    *get,Displacement_y(i),Node,num_node,U,y',newline,...
                '    *get,Displacement_z(i),Node,num_node,U,z',newline,...
                '*enddo',newline,...
                'allsel',newline,newline,...
                '! 导出数据',newline,...
                '*cfopen,Displacement,txt',newline,...
                '*vwrite,Displacement_x(1),Displacement_y(1),Displacement_z(1)',newline,...
                '(3E20.8)',newline,...
                '*cfclos',newline];
    OutputMethod_clone.outputAPDL(output_str,'getDisplacement.mac','w')

    % 修改OutputMethod属性值，并运行宏文件
    OutputMethod_clone.MacFilePath = fullfile(OutputMethod_clone.WorkPath,'getDisplacement.mac');
    OutputMethod_clone.ResultFilePath = fullfile(OutputMethod_clone.WorkPath,'getDisplacement.out');
    OutputMethod_clone.runMac("ComputingMode","Distributed")

    % 数据导入MATLAB
    dataFilePath = fullfile(OutputMethod_clone.WorkPath,'Displacement.txt');
    fileID = fopen(dataFilePath, 'r');
    data = readmatrix(dataFilePath);
    fclose(fileID);

    % 分解数据
    Ux = data(:,1)';
    Uy = data(:,2)';
    Uz = data(:,3)';
end