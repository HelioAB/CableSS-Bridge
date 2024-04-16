classdef MaterialData_Cable < LinkOrBeam
    methods
        function obj = MaterialData_Cable()
            obj = obj@LinkOrBeam(...
                                2.05e11,...      % 弹性模量
                                0.3,...         % 泊松比
                                7.85e4,...        % 容重, N/m^3
                                1.2e-5)         % 线膨胀系数
            obj.MaterialType = 'Cable';
        end
    end
end