import org.nlogo.headless.HeadlessWorkspace
import org.scalatest.FunSuite

class TestSuite extends FunSuite {

  test("test") {
      val workspace = HeadlessWorkspace.newInstance
      workspace.open("my-model.nlogo")
      try {
        workspace.command("test")
      } catch {
        case ex: Serializable => throw ex
        case ex: Exception =>
          // ScalaTest chokes on non-Serializable exceptions
          // so we wrap it in a generic exception if needed
          val msg = ex.getMessage + "\n" +
            ex.getStackTrace.map("  " + _).mkString("\n")
          throw new Exception(msg)
      } finally {
        workspace.dispose()
      }
  }
}
