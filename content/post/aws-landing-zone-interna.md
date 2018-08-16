## Interna

Intern funktioniert es uebrigens so, dass in der Konfiguration im Template `aws-landing-zone-configuration/templates/aws_baseline/aws-landing-zone-avm.template.j2` eine Schleife ueber die `baseline_resources` im Manifest iteriert wird und darueber festgelegt wird, welche Stack Sets im CloudFormation Template fuer die Account Vending Machine, welche die verwalteten Sub-Accounts provisioniert, landen.

Hier der Prozess im Einzelnen:

 1. Aenderung der Config
 1. Trigger der Landing Zone CodePipeline
 1. CodeBuild Step rendert die Jinja (`j2`)Templates.
 'StackSetEnableSuperluminarRules':
     'DependsOn':
     - 'Organizations'
     - 'DetachSCP'
     - 'StackSetEnableConfig'
     'Type': 'Custom::StackInstance'
     'Properties':
       'StackSetName': 'AWS-Landing-Zone-Baseline-EnableSuperluminarRules'
       'TemplateURL': ''
       'AccountList':
       - 'Fn::GetAtt': 'Organizations.AccountId'
       'RegionList':
       - 'eu-west-1'
       'ServiceToken': 'arn:aws:lambda:eu-west-1:123456789012:function:LandingZone'
 4.  und gibt diese als Artefakt an die naechsten Pipeline Schritte weiter. 

<CloudFormation ScreenShot here>

Da reingerendert wird, fuehrt der Service Catalog jetzt 
