{-# LANGUAGE MultiParamTypeClasses #-}
module Control.Effect.Lift
( Lift(..)
, runM
) where

import Control.Effect.Handler
import Control.Effect.Internal
import Control.Effect.Lift.Internal

runM :: Monad m => Eff (LiftH m) a -> m a
runM = runLiftH . interpret

newtype LiftH m a = LiftH { runLiftH :: m a }

instance Monad m => Carrier (LiftH m) (Lift m) where
  gen = LiftH . pure
  con = LiftH . (>>= runLiftH) . unLift
