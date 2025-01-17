function bridgeobj = loadBridgeObj(obj,options)
    arguments
        obj
        options.ifReplaceOutputObj = true
    end
    % 判断，如果是一个cell，就遍历cell中的所有；如果是char或string，就直接使用该变量
    path_bridge = obj.WorkPath;
    path_bridgeobj = fullfile(path_bridge,'BridgeObj.mat');
    if ~exist(path_bridgeobj,'file')
        str_error = sprintf('没有找到%s',path_bridgeobj);
        error(str_error);
    end
    loaded_data = load(path_bridgeobj,'bridge');
    bridgeobj = loaded_data.bridge;
    if options.ifReplaceOutputObj
        obj.OutputObj = bridgeobj;
    end
end