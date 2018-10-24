function image_overlay(ax,under,over,m)

%%
under = imrotate(under,90);
under = mat2gray(under);
[under,map] = gray2ind(under,m);
under = ind2rgb(under,map);
imshow(under,'Parent',ax)
hold(ax,'on')

%%
over = imrotate(over,90);
a = zeros(size(over));
a(~isnan(over(:))) = 0.5;
over = mat2gray(over);
over = gray2ind(over,m);
map = jet(m);
%map(:) = rand(size(map(:)));
over = ind2rgb(over,map);
h = imshow(over,'Parent',ax);
set(h,'AlphaData',a);
