function draw_color_traj(embed_coord, colors, add_identity, ticklabels, figure_id)
    if ~exist('figure_id', 'var') figure_id = randi(100) + 1000; end
    fig = figure(figure_id);
    fig.Position = [700 700 1000 1000];

    if add_identity == 1
        plot(embed_coord(2:end,1), embed_coord(2:end,2), 'k-');
        hold on
        scatter(embed_coord(1,1), embed_coord(1,2), 120, [0 0 1], 'pentagram');
    else
        plot(embed_coord(:,1), embed_coord(:,2),'b-');
    end
    axis equal
    xlabel('\it x'); ylabel('\it y'); zlabel('\it z');
    grid on
    hold on 

    scatter(embed_coord(:,1), embed_coord(:,2), 24, colors, 'filled');
    colormap(colors);
    c = colorbar;
    c.Ticks = linspace(0,1,size(ticklabels,2));
    c.TickLabels = ticklabels;
    c.Box = 'on';
    c.TickDirection = 'out';
    set(gca,'FontName','Times New Roman','FontSize',14,'LineWidth',1);
end