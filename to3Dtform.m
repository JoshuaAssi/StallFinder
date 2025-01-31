function [tform] = to3Dtform(T)

T = padarray(T, 1, 0, 'pre');
T = padarray(T', 1, 0, 'pre')';
T(1,1) = T(2,2);
T(2,2) = 1;
T(1,3) = -T(2,3);
T(2,3) = 0;
T(3,1) = -T(3,2);
T(3,2) = 0;
T(4,1) = T(4,3);
T(4,3) = T(4,2);
T(4,2) = 0;

tform = T;

end