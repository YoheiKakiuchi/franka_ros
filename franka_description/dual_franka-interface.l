(require :robot-interface "package://pr2eus/robot-interface.l")
(require :dual_franka "package://franka_description/dual_franka.l")

(defclass dual_franka-robot-interface
  :super robot-interface
  :slots ())
(defmethod dual_franka-robot-interface
  (:init
   (&rest args &key ((:controller-timeout ct) nil))
   (prog1
       (send-super* :init :robot dual_franka-robot :controller-timeout ct args)
     ;; do something
     ))
  (:default-controller
   ()
   (list
    (list
     (cons :controller-action "fullbody_controller/follow_joint_trajectory")
     (cons :controller-state "fullbody_controller/state")
     (cons :action-type control_msgs::FollowJointTrajectoryAction)
     (cons :joint-names (mapcar #'(lambda (n) (if (symbolp n) (symbol-name n) n)) (send-all (send robot :joint-list) :name))))))
  )

(defun dual_franka-init ()
  (setq *ri* (instance dual_franka-robot-interface :init))
  (setq *robot* (dual_franka))
  )
