function output_str = outputMain(obj,fileName,options)
    arguments
        obj
        fileName = 'main.mac'
        options.flag_Load = true
        options.flag_Solve = true
    end
    
    if options.flag_Load
        output_load_str = '/input,defLoad,mac,,,0						!10. 定义荷载';
    else
        output_load_str = '! /input,defLoad,mac,,,0						!10. 定义荷载';
    end

    if options.flag_Solve
        output_solve_str = ['/input,defSolve,mac,,,0                     !12. 求解选项设置与求解',newline,...
                             sprintf('save,%s,db',[obj.JobName,'Result']),newline];
    else
        output_solve_str = ['! /input,defSolve,mac,,,0                     !12. 求解选项设置与求解',newline,...
                             sprintf('! save,%s,db',[obj.JobName,'Result']),newline];
    end

    output_str = ['finish $ /clear',newline,newline,...
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
                  output_load_str,newline,...
                  '/input,defCoupling,mac,,,0                  !11. 定义耦合',newline,...
                  sprintf('save,%s,db',obj.JobName),newline,...
                  'finish',newline,newline,...
                  '! 分析与求解选项设置',newline,...
                  output_solve_str];
                  
    obj.outputAPDL(output_str,fileName,'w');
end