resource "aws_sfn_state_machine" "sfn_state_machine" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  depends_on = [
    aws_lambda_function.source
  ]

  name     = var.step_function_state_machine_name
  role_arn = aws_iam_role.lambda_role[0].arn

  definition = jsonencode({
    "Comment" : "This step will delete any previously created failsafe snapshots",
    "StartAt" : "AuthorizeUser",
    "States" : {
      "AuthorizeUser" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-00-AuthorizeUser",
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "MaskopyTimeoutException",
              "States.Timeout"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          },
          {
            "ErrorEquals" : [
              "MaskopyThrottlingException"
            ],
            "IntervalSeconds" : 5,
            "MaxAttempts" : 3,
            "BackoffRate" : 4
          },
          {
            "ErrorEquals" : [
              "TypeError",
              "NameError",
              "KeyError"
            ],
            "MaxAttempts" : 0
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.AuthorizationError",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "OutputPath" : "$",
        "ResultPath" : null,
        "Next" : "UseExistingSnapshot"
      },
      "UseExistingSnapshot" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-01-UseExistingSnapshot",
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.Unknown",
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "MaskopyResourceException",
              "States.Timeout"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          },
          {
            "ErrorEquals" : [
              "MaskopyThrottlingException"
            ],
            "IntervalSeconds" : 5,
            "MaxAttempts" : 3,
            "BackoffRate" : 4
          },
          {
            "ErrorEquals" : [
              "TypeError",
              "NameError",
              "KeyError"
            ],
            "MaxAttempts" : 0
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.ErrorResult",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "ResultPath" : "$.CreatedSnapshots",
        "Next" : "CreationWait"
      },
      "CreationWait" : {
        "Type" : "Wait",
        "Seconds" : 180,
        "Next" : "CheckCreationStatus"
      },
      "CheckCreationStatus" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-02-CheckForSnapshotCompletion",
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "MaskopyResourceException",
              "States.Timeout"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          },
          {
            "ErrorEquals" : [
              "MaskopyThrottlingException"
            ],
            "IntervalSeconds" : 5,
            "MaxAttempts" : 3,
            "BackoffRate" : 4
          },
          {
            "ErrorEquals" : [
              "TypeError",
              "NameError",
              "KeyError"
            ],
            "MaxAttempts" : 0
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.ErrorResult",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "ResultPath" : "$.SnapshotsAvailable",
        "OutputPath" : "$",
        "Next" : "CreationComplete"
      },
      "CreationComplete" : {
        "Type" : "Choice",
        "Choices" : [
          {
            "Variable" : "$.SnapshotsAvailable",
            "BooleanEquals" : true,
            "Next" : "ShareSnapshots"
          }
        ],
        "Default" : "CreationWait"
      },
      "ShareSnapshots" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-03-ShareSnapshots",
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "MaskopyResourceException",
              "States.Timeout"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          },
          {
            "ErrorEquals" : [
              "TypeError", "NameError", "KeyError"
            ],
            "MaxAttempts" : 0
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.SharedSnapshots",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "ResultPath" : "$.SharedSnapshots",
        "OutputPath" : "$",
        "Next" : "CreateDestinationSnapshots"
      },
      "CreateDestinationSnapshots" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-04-CopySharedDBSnapshots",
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "MaskopyResourceException",
              "States.Timeout"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          },
          {
            "ErrorEquals" : [
              "TypeError",
              "NameError",
              "KeyError"
            ],
            "MaxAttempts" : 0
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.CreatedDestinationSnapshots",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "ResultPath" : "$.CreatedDestinationSnapshots",
        "OutputPath" : "$",
        "Next" : "CreationDestinationWait"
      },
      "CreationDestinationWait" : {
        "Type" : "Wait",
        "Seconds" : 180,
        "Next" : "CheckDestinationCreationStatus"
      },
      "CheckDestinationCreationStatus" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-05-CheckForDestinationSnapshotCompletion",
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "MaskopyResourceException",
              "States.Timeout"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          },
          {
            "ErrorEquals" : [
              "MaskopyThrottlingException"
            ],
            "IntervalSeconds" : 5,
            "MaxAttempts" : 3,
            "BackoffRate" : 4
          },
          {
            "ErrorEquals" : [
              "TypeError", "NameError", "KeyError"
            ],
            "MaxAttempts" : 0
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.DestinationSnapshotsAvailable",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "ResultPath" : "$.DestinationSnapshotsAvailable",
        "OutputPath" : "$",
        "Next" : "DestinationCreationComplete"
      },
      "DestinationCreationComplete" : {
        "Type" : "Choice",
        "Choices" : [
          {
            "Variable" : "$.DestinationSnapshotsAvailable",
            "BooleanEquals" : true,
            "Next" : "RestoreDatabases"
          }
        ],
        "Default" : "CreationDestinationWait"
      },
      "RestoreDatabases" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-06-RestoreDatabases",
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "MaskopyResourceException",
              "States.Timeout"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          },
          {
            "ErrorEquals" : [
              "TypeError", "NameError", "KeyError"
            ],
            "MaxAttempts" : 0
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.DestinationRestoredDatabases",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "ResultPath" : "$.DestinationRestoredDatabases",
        "OutputPath" : "$",
        "Next" : "RestoreDBWait"
      },
      "RestoreDBWait" : {
        "Type" : "Wait",
        "Seconds" : 300,
        "Next" : "CheckRestoreStatus"
      },
      "CheckRestoreStatus" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-07-CheckForRestoreCompletion",
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "MaskopyResourceException",
              "States.Timeout"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          },
          {
            "ErrorEquals" : [
              "MaskopyThrottlingException"
            ],
            "IntervalSeconds" : 5,
            "MaxAttempts" : 3,
            "BackoffRate" : 4
          },
          {
            "ErrorEquals" : [
              "TypeError",
              "NameError",
              "KeyError",
              "MaskopyDBInstanceStatusException"
            ],
            "MaxAttempts" : 0
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.DestinationRestoredDatabasesComplete",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "ResultPath" : "$.DestinationRestoredDatabasesComplete",
        "OutputPath" : "$",
        "Next" : "RestoreComplete"
      },
      "RestoreComplete" : {
        "Type" : "Choice",
        "Choices" : [
          {
            "Variable" : "$.DestinationRestoredDatabasesComplete",
            "BooleanEquals" : true,
            "Next" : "CreateFargate"
          }
        ],
        "Default" : "RestoreDBWait"
      },
      "CreateFargate" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-08a-CreateFargate",
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "MaskopyResourceException",
              "States.Timeout"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          },
          {
            "ErrorEquals" : [
              "MaskopyResourceException"
            ],
            "IntervalSeconds" : 5,
            "MaxAttempts" : 3,
            "BackoffRate" : 4
          },
          {
            "ErrorEquals" : [
              "TypeError",
              "NameError",
              "KeyError"
            ],
            "MaxAttempts" : 0
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.fargate",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "ResultPath" : "$.fargate",
        "OutputPath" : "$",
        "Next" : "FargateRunTask"
      },
      "FargateRunTask" : {
        "Type" : "Task",
        "Resource" : "arn:aws:states:::ecs:runTask.sync",
        "InputPath" : "$.fargate",
        "Retry" : [
          {
            "ErrorEquals" : [
              "States.Timeout",
              "States.TaskFailed",
              "States.Permissions"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.ECSRunTask",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "Parameters" : {
          "LaunchType" : "FARGATE",
          "Cluster.$" : "$.ClusterName",
          "TaskDefinition.$" : "$.TaskDefinition",
          "NetworkConfiguration" : {
            "AwsvpcConfiguration" : {
              "AssignPublicIp" : "DISABLED",
              "SecurityGroups" : [aws_security_group.maskopy_app[0].id],
              "Subnets" : var.staging_subnet_ids
            }
          }
        },
        "ResultPath" : "$.ECSRunTask",
        "OutputPath" : "$",
        "Next" : "TakeFinalSnapshot"
      },
      "TakeFinalSnapshot" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-09-TakeSnapshot",
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "MaskopyResourceException",
              "States.Timeout"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          },
          {
            "ErrorEquals" : [
              "TypeError",
              "NameError",
              "KeyError"
            ],
            "MaxAttempts" : 0
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.CreatedFinalSnapshots",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "ResultPath" : "$.CreatedFinalSnapshots",
        "OutputPath" : "$",
        "Next" : "FinalSnapshotWait"
      },
      "FinalSnapshotWait" : {
        "Type" : "Wait",
        "Seconds" : 180,
        "Next" : "CheckFinalSnapshotavailability"
      },
      "CheckFinalSnapshotavailability" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-10-CheckFinalSnapshotAvailability",
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException",
              "MaskopyResourceException",
              "States.Timeout"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2
          },
          {
            "ErrorEquals" : [
              "MaskopyThrottlingException"
            ],
            "IntervalSeconds" : 5,
            "MaxAttempts" : 3,
            "BackoffRate" : 4
          },
          {
            "ErrorEquals" : [
              "TypeError",
              "NameError",
              "KeyError"
            ],
            "MaxAttempts" : 0
          }
        ],
        "Catch" : [
          {
            "ErrorEquals" : ["States.ALL"],
            "ResultPath" : "$.FinalSnapshotAvailable",
            "Next" : "ErrorHandlingAndCleanup"
          }
        ],
        "ResultPath" : "$.FinalSnapshotAvailable",
        "OutputPath" : "$",
        "Next" : "FinalSnapshotComplete"
      },
      "FinalSnapshotComplete" : {
        "Type" : "Choice",
        "Choices" : [
          {
            "Variable" : "$.FinalSnapshotAvailable",
            "BooleanEquals" : true,
            "Next" : "CleanupAndTagging"
          }
        ],
        "Default" : "FinalSnapshotWait"
      },
      "ErrorHandlingAndCleanup" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-ErrorHandlingAndCleanup",
        "Retry" : [
          {
            "ErrorEquals" : [
              "TypeError",
              "NameError",
              "KeyError"
            ],
            "MaxAttempts" : 0
          },
          {
            "ErrorEquals" : [
              "MaskopyThrottlingException"
            ],
            "IntervalSeconds" : 5,
            "MaxAttempts" : 3,
            "BackoffRate" : 4
          },
          {
            "ErrorEquals" : ["States.ALL"],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2.0
          }
        ],
        "ResultPath" : "$.DeletedResources",
        "OutputPath" : "$",
        "Next" : "Publish Failure"
      },
      "Publish Failure" : {
        "Type" : "Task",
        "Resource" : "arn:aws:states:::sqs:sendMessage",
        "InputPath" : "$",
        "Parameters" : {
          "QueueUrl" : "https://sqs.${data.aws_region.current.name}.amazonaws.com/${data.aws_caller_identity.staging.account_id}/${var.sqs_queue_name}",
          "MessageBody.$" : "$.DeletedResources[0].Message"
        },
        "Next" : "FailureState"
      },
      "FailureState" : {
        "Type" : "Fail",
        "Cause" : "Error Occurred in one of the steps",
        "Error" : "Error"
      },
      "CleanupAndTagging" : {
        "Type" : "Task",
        "Resource" : "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:function:MASKOPY-11-CleanupAndTagging",
        "Retry" : [
          {
            "ErrorEquals" : [
              "States.TaskFailed"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2.0
          },
          {
            "ErrorEquals" : [
              "MaskopyThrottlingException"
            ],
            "IntervalSeconds" : 5,
            "MaxAttempts" : 3,
            "BackoffRate" : 4
          },
          {
            "ErrorEquals" : [
              "States.ALL"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 2,
            "BackoffRate" : 2.0
          }
        ],
        "ResultPath" : "$.CleanupAndTagging",
        "OutputPath" : "$",
        "Next" : "Publish Success"
      },
      "Publish Success" : {
        "Type" : "Task",
        "Resource" : "arn:aws:states:::sqs:sendMessage",
        "InputPath" : "$",
        "Parameters" : {
          "QueueUrl" : "https://sqs.${data.aws_region.current.name}.amazonaws.com/${data.aws_caller_identity.staging.account_id}/${var.sqs_queue_name}",
          "MessageBody.$" : "$.CleanupAndTagging[1].Message"
        },
        "ResultPath" : "$.Publish",
        "OutputPath" : "$",
        "Next" : "ChoiceState"
      },
      "ChoiceState" : {
        "Type" : "Choice",
        "Choices" : [
          {
            "Not" : {
              "Variable" : "$.CleanupAndTagging[0].Success",
              "BooleanEquals" : false
            },
            "Next" : "SuccessState"
          },
          {
            "Not" : {
              "Variable" : "$.CleanupAndTagging[0].Success",
              "BooleanEquals" : true
            },
            "Next" : "FailureState"
          }
        ],
        "Default" : "SuccessState"
      },
      "SuccessState" : {
        "Type" : "Succeed"
      }
    }
  })
}