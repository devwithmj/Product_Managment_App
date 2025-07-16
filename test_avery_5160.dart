import 'lib/models/label_template.dart';
import 'lib/utils/label_arrengment_helper.dart';

void main() {
  print('Testing Avery 5160 template validation...');

  // Validate the new Avery 5160 template
  LabelArrangementHelper.printValidationReport(LabelTemplates.avery5160);

  // Also validate all templates to ensure nothing is broken
  print('\n\nValidating all templates:');
  LabelArrangementHelper.validateAllTemplates();
}
