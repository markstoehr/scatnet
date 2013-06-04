x = lena;
x = x(128:128+255, 128:128+255);

options.null = 1;
% antialiasing must be set to infty
% so that scattering of original and rotated
% image will be sampled at exactly the same points
options.antialiasing = 10;

wavelet = wavelet_factory_3d(size(x), options);

% compute scattering of x
sx = scat(x, wavelet);
sx_raw = format_scat(sx);

% compute scattering of x rotated by pi/2
x_rot = rot90(x,1);
sx_rot = scat(x_rot, wavelet);
sx_rot_raw = format_scat(sx_rot);

% rotate back every layer of output
for p = 1:size(sx_rot_raw,3)
	sx_rot_raw_back(:,:,p) = rot90(sx_rot_raw(:,:,p), -1);
end

% compute norm ratio
norm_diff = sqrt(sum((sx_rot_raw_back(:)-sx_raw(:)).^2));
norm_s = sqrt(sum((sx_raw(:)).^2));
norm_ratio = norm_diff/norm_s