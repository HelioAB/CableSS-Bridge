function [P_cable_x,P_cable_y,P_cable_z,P_girder_x,P_girder_y,P_girder_z] = getP(obj,P_girder_z)
    arguments
        obj
        P_girder_z {mustBeNumeric(P_girder_z)}
    end
    % 输入：P_girder_z: 斜拉索下端（梁端）的竖向受力，向z正方向为正。通常情况符号为负号，表示斜拉索受拉。数值向量
    % 输出：斜拉索的受力，z正方向为正
    % 输入输出均为StayedCable的受力，符号满足整体坐标系符号

    % 参数验证
    if length(P_girder_z)==1
        P_girder_z = P_girder_z+zeros(1,length(obj.Line));
    end
    mustBeEqualSize(P_girder_z,obj.Line)

    w = obj.Material.MaterialData.gamma .* obj.Section.Area; % 每延米自重
    P_cable_z_k = -P_girder_z;
    eps = 0.005; % 可修改收敛误差
    iter_num = 100;
    iter_count = 0;
    err = 1;
    [delta_x,delta_y,delta_z] = obj.Line.DeltaLength;

    [~,sign_cable_tension] = obj.getHangerTensionDirectionAtCable();
    sign_girder_tension = -sign_cable_tension;

    P_girder_z = abs(P_girder_z) .* sign_girder_tension(:,3)';
    while err>eps
        unstressed_length = obj.getUnstressedLengthByForce(P_cable_z_k);
        P_w_k = -w.*unstressed_length;
        P_cable_z_k1 = -(P_girder_z + P_w_k);
        err = max((P_cable_z_k1-P_cable_z_k)./P_cable_z_k);
        P_cable_z_k = P_cable_z_k1;
        iter_count = iter_count+1;
        if iter_count>iter_num
            error('超出迭代次数限制')
        end
    end

    P_girder_y = abs((P_w_k.*delta_y/2 + delta_y.*P_girder_z) ./ delta_z) .* sign_girder_tension(:,2)';
    P_girder_x = abs(P_girder_y .* delta_x ./ delta_y) .* sign_girder_tension(:,1)';

    P_cable_z = abs(P_cable_z_k) .* sign_cable_tension(:,3)';
    P_cable_y = abs((P_w_k.*delta_y/2 + delta_y.*P_cable_z) ./ delta_z) .* sign_cable_tension(:,2)';
    P_cable_x = abs(P_cable_y .* delta_x ./ delta_y) .* sign_cable_tension(:,1)';
    
    obj.InternalForce = sqrt(((abs(P_girder_x)+abs(P_cable_x))./2).^2 + ((abs(P_girder_y)+abs(P_cable_y))./2).^2 + ((abs(P_girder_z)+abs(P_cable_z))./2).^2);
    obj.UnstressedLength = obj.getUnstressedLengthByForce(P_cable_z);
    obj.Strain = obj.getStrain;
    obj.Params.P_girder_x = P_girder_x;% 存储hanger在梁端的受力
    obj.Params.P_girder_y = P_girder_y;
    obj.Params.P_girder_z = P_girder_z;
    obj.Params.P_cable_x = P_cable_x;% 存储hanger在主缆端的受力
    obj.Params.P_cable_y = P_cable_y;
    obj.Params.P_cable_z = P_cable_z;
end
function mustBeEqualSize(a,b)
    if ~isequal(size(a),size(b))
        eid = 'Size:notEqual';
        msg = '输入值必须有相同的size。';
        throwAsCaller(MException(eid,msg))
    end
end