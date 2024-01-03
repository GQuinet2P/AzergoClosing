global class P2C_OptionValueLabel implements Comparable {
    public String value;
    public String label;
    public Boolean isReference = false;
    public Boolean isSortable;
    public String type;
    public List<P2C_OptionValueLabel> restrictedValues;
    public List<P2C_OptionValueLabel> referenceTargets;
    public Map<String, List<P2C_OptionValueLabel>> referenceTargetsFields;

    public P2C_OptionValueLabel(String key, String label) {
        this.value = key;
        this.label = label;
    }

    global Integer compareTo(Object compareTo) {
        P2C_OptionValueLabel toCompare = (P2C_OptionValueLabel)compareTo;

        Integer result = label.compareTo(toCompare.label);
        if (result == 0) {
            System.debug('Same label, compare key');
            return value.compareTo(toCompare.value);
        } else {
            return result;
        }
    }
}