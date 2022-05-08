function DrawPosition(obj, plt, data,nameval)
%DRAWPOSITION Summary of this function goes here
%   Detailed explanation goes here

if (nameval.data == "angles")
    T = obj.getForwardKinematics(data, "toolRelated",false, ...
            "useLocalSolver",true);
    plot3(plt, T.Flange(1,4,end), T.Flange(2,4,end), T.Flange(3,4,end), nameval.symbol);
elseif (nameval.data == "transMatrix")
    plot3(plt, data(1,4,end), data(2,4,end), data(3,4,end), nameval.symbol);
else
    plot3(plt, data(1), data(2), data(3), nameval.symbol);
end

hold on;

if (nameval.drawRobotPose == true && nameval.data ~= "coords")
    if (nameval.data == "angles")
        T = obj.getForwardKinematics(data, "toolRelated",false, ...
            "useLocalSolver",true);
        coords = [0,0,0; ...
            T.JBase(1:3,4)'; ...
            T.J1(1:3,4)'; ...
            T.J2(1:3,4)'; ...
            T.J3(1:3,4)'; ...
            T.J4(1:3,4)'; ...
            T.J5(1:3,4)'; ...
            T.J6(1:3,4)'; ...
            T.J7(1:3,4)'; ...
            T.Flange(1:3,4)';];
    else
        warning("The robot configuration is predicted using inverse" + ...
            " kinematics and may not match the actual data!")
        T = obj.getInverseKinematics(T', orient', "joints", ...
            ang(end,:), "useLocalSolver", true, "toolRelated", false);
    end
    plot3(coords(:,1),coords(:,2),coords(:,3),'-o', 'LineWidth',8);
else
    %ME Exception
end
hold on;
end

