function Pz = getSupportedForce(obj)
    % 导出
    OutputMethod = obj.OutputMethod;
    obj.OutputMethod.OutputObj = obj;
    OutputMethod.outputElementType;
    OutputMethod.outputMaterial;
    OutputMethod.outputSection;
    OutputMethod.outputReal;
    OutputMethod.outputKeyPoint;
    OutputMethod.outputLine;
    OutputMethod.outputLineAttribution;
    OutputMethod.outputLineMesh;
    OutputMethod.outputConstraint;
    OutputMethod.outputLoad;
    OutputMethod.outputCoupling;
    OutputMethod.outputSolve;
    
    str_main = ['finish $ /clear',newline,newline,...
                  '/prep7',newline,...
                  '*set,g,9.806 $ acel,,,g  !重力加速度，设为Z方向, m/s^2',newline,...
                  '/input,defElementType,mac,,,0  				!1. 定义单元类型',newline,...
                  '/input,defMaterial,mac,,,0  			    !2. 定义材料属性',newline,...
                  '/input,defSection,mac,,,0					!3. 定义截面数据',newline,...
                  '/input,defReal,mac,,,0  					!4. 定义实常数',newline,...
                  '/input,defKeyPoint,mac,,,0					!5. 定义关键点',newline,...
                  '/input,defLine,mac,,,0						!6. 定义线',newline,...
                  '/input,defLineAttribution,mac,,,0           !7. 定义Line的属性',newline,...
                  '/input,defLineMesh,mac,,0                   !8. 划分单元',newline,...
                  '/input,defConstraint,mac,,,0				!9. 定义约束',newline,...
                  '/input,defLoad,mac,,,0						!10. 定义荷载',newline,...
                  '/input,defCoupling,mac,,,0                  !11. 定义耦合',newline,...
                  sprintf('save,%s,db',OutputMethod.JobName),newline,...
                  'finish',newline,newline,...
                  '! 分析与求解选项设置',newline,...
                  '/input,defSolve,mac,,,0                     !12. 求解选项设置与求解',newline,...
                  sprintf('save,%s,db',[OutputMethod.JobName,'Result']),newline,...
                  '/input,getReaction,mac,,,0'];
                  
    OutputMethod.outputAPDL(str_main,'main.mac','w');
    
    num_kp = [obj.SupportedPoint.Num];
    str_getReaction = ['/post1',newline,...
                        sprintf('resume,%s,db',[OutputMethod.JobName,'Result']),newline,...
                        'set,1,last',newline,newline,...
                        sprintf('count_kp = %d',length(num_kp)),newline,...
                        OutputMethod.outputArray(num_kp,'num_kp'),newline,...
                        '*dim,Rz,array,count_kp',newline,...
                        '*do,i,1,count_kp,1',newline,...
                        '    ksel,s,,,num_kp(i)',newline,...
                        '    nslk,s',newline,...
                        '    *get,num_node,node,0,num,max',newline,...
                        '    *get,Rz(i),node,num_node,RF,Fz',newline,...
                        '*enddo',newline,newline,...
                        '*cfopen,Reaction,txt',newline,...
                        '*vwrite,Rz(1)',newline,...
                        '(1E20.8)',newline,...
                        '*cfclos',newline,newline,...
                        'allsel'];
    OutputMethod.outputAPDL(str_getReaction,'getReaction.mac','w');
    % 运行
    obj.run("ComputingMode","Distributed");

    % 提取支反力
    fileID = fopen(fullfile(OutputMethod.WorkPath,"Reaction.txt"), 'r');
    Pz = fscanf(fileID, '%e\n');
    fclose(fileID);
end