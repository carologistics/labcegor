find_package(Protobuf REQUIRED)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS AgentTask.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS AttentionMessage.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS BeaconSignal.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS ConveyorVisionResult.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS ExplorationInfo.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS GameInfo.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS GameState.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS LightSignals.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS LockMasterAnnounce.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS LockMessage.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS MachineCommands.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS MachineDescription.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS MachineInfo.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS MachineInstructions.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS MachineReport.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS NavigationChallenge.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS OrderInfo.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS Pose2D.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS Pose3D.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS PreparedForProduction.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS ProductColor.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS PuckDetectionResult.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS PuckInfo.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS RingInfo.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS RobotCommands.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS RobotInfo.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS SimTimeSync.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS Sync.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS Team.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS Time.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS VersionInfo.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS Worldmodel.proto)
protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS Zone.proto)
