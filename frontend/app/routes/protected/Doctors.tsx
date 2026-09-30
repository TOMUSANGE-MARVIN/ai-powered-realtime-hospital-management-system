import { useSearchParams } from "react-router";
import UserManagement from "@/components/users/UserManagement";
import VerificationQueue from "@/components/doctors/VerificationQueue";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export function meta() {
  return [{ title: "Doctors" }];
}

const Doctors = () => {
  // ?tab=verification — where the "Doctor awaiting verification"
  // notification links.
  const [params, setParams] = useSearchParams();
  const tab = params.get("tab") === "verification" ? "verification" : "accounts";

  return (
    <Tabs
      value={tab}
      onValueChange={(value) =>
        setParams(value === "verification" ? { tab: value } : {}, { replace: true })
      }
      className="space-y-4"
    >
      <TabsList>
        <TabsTrigger value="accounts">Accounts</TabsTrigger>
        <TabsTrigger value="verification">Licence verification</TabsTrigger>
      </TabsList>
      <TabsContent value="accounts">
        <UserManagement
          role="doctor"
          title="Doctors"
          description="Manage doctor accounts"
        />
      </TabsContent>
      <TabsContent value="verification">
        <VerificationQueue />
      </TabsContent>
    </Tabs>
  );
};

export default Doctors;
