# encoding: utf-8
module TreeHelper

  #  hacks at rendering nested set, made redundant for reference sake, will be cleaned up!
  
  # _n
  #  <div style="border-left: 2px solid green; padding-left: 0px; position: relative; left: 5px "><%= n.label.to_s %></div>
  # <%= n.tree.max_depth.to_s + " - " + n.depth.to_s -%> 
  
  def r(root_node, txt, depth = 0)
    # returns terminals only
    s = txt + render(:partial => 'n', :object => root_node)
    return s if root_node.children.size == 0 
    root_node.children.collect{|n| r(n, txt)}
  end
  

  def r1(root_node, txt, depth = 0)
    # returns terminals only
    s = '<div style=" margin-left: 10px; border-left: 2px solid black;">' + render(:partial => 'n', :object => root_node)
    txt = root_node.children.collect{|n| r1(n, s)}.join(" ")
    return s + txt + '</div>'
  end
  
  def r2(root_node, txt, depth = 0)
    # returns terminals only

    s = '<div style=" margin-right: 10px;  margin-top: 5px; border: 1px solid green; background-color: rgb(' + ColorHelper::ranged_color(root_node.pct_depth, 'green') + '); margin: 4px; ">' + render(:partial => 'n', :object => root_node)
        depth = depth + 1
      txt = root_node.children.collect{|n| r2(n, s, depth)}.join(" ")
     return s + '<div style=" border-left: 2px solid purple; border-bottom: 2px solid purple; margin-left: 10px; position: relative;   ">' +  txt + '</div>'  + '</div>'
  end
  
  def r3(root_node, txt, depth = 0)
    # returns terminals only

    s = '<div style="margin: 5px; border: 1px solid green; background-color: rgb(' + ColorHelper::ranged_color(root_node.pct_depth, 'green') + '); ">' + render(:partial => 'n', :object => root_node)
        depth = depth + 1
      txt = root_node.children.collect{|n| r3(n, s, depth)}.join(" ")
     return s +  txt +  '</div>'
  end
  
  def r4(root_node, txt, depth = 0)
    # returns terminals only
      s = '<div>' # style="margin: 5px; border: 1px solid green; background-color: rgb(' + ColorHelper::ranged_color(root_node.pct_depth, 'green') + '); ">' + render(:partial => 'n', :object => root_node)
      depth = depth + 1
      txt = root_node.children.collect{|n| r3(n, s, depth)}.join(" ")
      return s +  txt +  '</div>'
  end
  
end
