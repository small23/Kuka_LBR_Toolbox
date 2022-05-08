function frames = TransformFramesToFlange(frames)
%TRANSFORMFRAMESTOFLANGE Summary of this function goes here
%   Detailed explanation goes here

for i=1:length(frames)
    for j=1:length(frames)
        if (i~=j)
            if contains(frames(j).name, frames(i).name)
                if count(erase(frames(j).name,frames(i).name),"/")==1
                    transform = getTransformMatrics(frames(i).coord, frames(i).orient);
                    source = getTransformMatrics(frames(j).coord, frames(j).orient);
                    R = transform * source;
                    frames(j).orient = rotm2eul(R(1:3,1:3));
                    frames(j).coord = R(1:3,4)';
                end
            end
        end
    end
end
end

function matrix = getTransformMatrics(eefVector, eefAngles)
     matrix = makehgtform('zrotate',eefAngles(1))*...
                    makehgtform('yrotate',eefAngles(2))*makehgtform('xrotate',eefAngles(3));
     matrix(1:3,4) = eefVector';
end