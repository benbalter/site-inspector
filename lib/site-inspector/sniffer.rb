class SiteInspector
  def sniff(type)
    results = Sniffles.sniff(body, type).select { |name, meta| meta[:found] == true }
    results.each { |name, result| result.delete :found} if results
    results
  end

  def cms
    sniff :cms
  end

  def analytics
    sniff :analytics
  end

  def javascript
    sniff :javascript
  end

  def advertising
    sniff :advertising
  end

end
