module TooltipHelper
  def tooltip_render(opts)
    CGI.escapeHTML(
      @controller.render_to_string(opts)
    ) end end
