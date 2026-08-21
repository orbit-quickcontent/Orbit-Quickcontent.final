"use client";

import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { toast } from "sonner";
import {
  LayoutDashboard,
  Building2,
  Users,
  Film,
  CheckSquare,
  CreditCard,
  TrendingUp,
  FileText,
  Activity,
  Settings,
  HelpCircle,
  Search,
  Bell,
  Sun,
  Moon,
  ChevronDown,
  LogOut,
  FolderLock,
  HardDrive,
  UserCheck,
  RefreshCw,
  Plus,
  KeyRound
} from "lucide-react";

// Mock SaaS Analytics charts data
const revenueChartData = [0, 0, 0, 0, 0, 0, 0]; // In Lakhs or thousands
const userChartData = [0, 0, 0, 0, 0, 0, 0];

export default function AdminDashboard() {
  const [activeModule, setActiveModule] = useState<string>("overview");
  const [darkMode, setDarkMode] = useState<boolean>(true);
  const [orgDropdownOpen, setOrgDropdownOpen] = useState<boolean>(false);
  const [profileDropdownOpen, setProfileDropdownOpen] = useState<boolean>(false);
  const [selectedOrg, setSelectedOrg] = useState<string>("Orbit India Corp");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);
  const [togglingVerify, setTogglingVerify] = useState<string | null>(null);

  const [seeding, setSeeding] = useState<boolean>(false);

  // States for database entities
  const [partners, setPartners] = useState<any[]>([]);
  const [clients, setClients] = useState<any[]>([]);
  const [bookings, setBookings] = useState<any[]>([]);
  const [logs, setLogs] = useState<any[]>([]);
  const [partnerCodes, setPartnerCodes] = useState<any[]>([]);
  
  // Modal states for Generate Code / Add Partner
  const [isGenerateModalOpen, setIsGenerateModalOpen] = useState(false);
  const [isGenerating, setIsGenerating] = useState(false);
  const [generateForm, setGenerateForm] = useState({
    partnerEmail: "",
    trainerName: "",
    trainingDate: new Date().toISOString().slice(0, 16) // default current local datetime
  });

  const [metrics, setMetrics] = useState<any>({
    totalBookings: 0,
    totalPartners: 0,
    onlinePartners: 0,
    totalClients: 0,
    verifiedPartners: 0,
    verificationRate: 0.0
  });

  const fetchLogsAndData = async () => {
    setLoading(true);
    try {
      const authHeaders = {
        Authorization: `Bearer ${localStorage.getItem("admin_token") || ""}`
      };

      const [overviewRes, partnersRes, bookingsRes, logsRes, codesRes] = await Promise.all([
        fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000"}/api/admin/overview`, { headers: authHeaders }),
        fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000"}/api/admin/partners?status=ACTIVE`, { headers: authHeaders }),
        fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000"}/api/admin/bookings`, { headers: authHeaders }),
        fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000"}/api/admin/audit-logs`, { headers: authHeaders }),
        fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000"}/api/admin/partner-codes`, { headers: authHeaders })
      ]);

      if (overviewRes.ok) {
        const overview = await overviewRes.json();
        setMetrics((prev: any) => ({
          ...prev,
          totalBookings: overview.totalBookings || 0,
          totalPartners: overview.totalPartners || 0,
          onlinePartners: overview.onlinePartners || 0,
          totalClients: overview.totalClients || 0,
          verifiedPartners: overview.verifiedPartners || 0
        }));
      }

      if (partnersRes.ok) {
        const pData = await partnersRes.json();
        setPartners(pData.partners || []);
      }

      if (bookingsRes.ok) {
        const bData = await bookingsRes.json();
        setBookings(bData.bookings || []);
      }

      if (logsRes.ok) {
        const lData = await logsRes.json();
        setLogs(lData || []);
      }

      if (codesRes.ok) {
        const cData = await codesRes.json();
        setPartnerCodes(cData.codes || []);
      }
    } catch {
      toast.error("Failed to load operations logs");
    } finally {
      setLoading(false);
    }
  };

  const handleGenerateCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsGenerating(true);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000"}/api/admin/partner-codes`, {
        method: "POST",
        headers: { 
          "Content-Type": "application/json",
          Authorization: `Bearer ${localStorage.getItem("admin_token") || ""}` 
        },
        body: JSON.stringify({
          partnerEmail: generateForm.partnerEmail,
          trainerName: generateForm.trainerName,
          trainingDate: new Date(generateForm.trainingDate).toISOString()
        })
      });

      if (res.ok) {
        toast.success("Partner enrollment code generated successfully");
        setIsGenerateModalOpen(false);
        setGenerateForm({ partnerEmail: "", trainerName: "", trainingDate: new Date().toISOString().slice(0, 16) });
        fetchLogsAndData();
      } else {
        const err = await res.json();
        toast.error(err.error || "Failed to generate code");
      }
    } catch {
      toast.error("Network error");
    } finally {
      setIsGenerating(false);
    }
  };

  const handleRevokeCode = async (id: string) => {
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000"}/api/admin/partner-codes/${id}`, {
        method: "DELETE",
        headers: { 
          "Content-Type": "application/json",
          Authorization: `Bearer ${localStorage.getItem("admin_token") || ""}` 
        },
        body: JSON.stringify({ reason: "Admin revocation via Dashboard" })
      });

      if (res.ok) {
        toast.success("Code revoked");
        fetchLogsAndData();
      } else {
        toast.error("Failed to revoke code");
      }
    } catch {
      toast.error("Network error");
    }
  };

  const handleSeedDatabase = async () => {
    toast.info("Database seeding is handled via backend scripts directly.");
  };

  useEffect(() => {
    fetchLogsAndData();
  }, []);

  const handleToggleVerification = async (partnerId: string, currentStatus: boolean) => {
    setTogglingVerify(partnerId);
    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000"}/api/admin/partners/${partnerId}/status`, {
        method: "PATCH",
        headers: { 
          "Content-Type": "application/json",
          Authorization: `Bearer ${localStorage.getItem("admin_token") || ""}`
        },
        body: JSON.stringify({ status: currentStatus ? "SUSPENDED" : "ACTIVE" }),
      });

      if (res.ok) {
        toast.success(currentStatus ? "Partner suspended" : "Partner activated successfully");
        fetchLogsAndData();
      } else {
        toast.error("Failed to update status");
      }
    } catch {
      toast.error("An error occurred");
    } finally {
      setTogglingVerify(null);
    }
  };

  const totalRevenue = bookings.reduce((sum, b) => sum + (b.packagePrice || 0), 0);
  const cloudStorageUsed = (bookings.length * 12.5).toFixed(1); // 12.5 GB per shoot
  const cloudStoragePercent = Math.min(100, Math.round((bookings.length * 12.5 / 5000) * 100)); // 5000 GB = 5 TB

  const getRevenueChartPoints = () => {
    if (bookings.length === 0) {
      return {
        points: "0,180 100,180 200,180 300,180 400,180 500,180 600,180",
        yCoords: [180, 180, 180, 180, 180, 180, 180]
      };
    }
    return {
      points: "0,180 100,170 200,150 300,110 400,80 500,50 600,20",
      yCoords: [180, 170, 150, 110, 80, 50, 20]
    };
  };

  const getUserChartPoints = () => {
    if (clients.length === 0) {
      return {
        points: "0,180 100,180 200,180 300,180 400,180 500,180 600,180",
        yCoords: [180, 180, 180, 180, 180, 180, 180]
      };
    }
    return {
      points: "0,180 100,165 200,140 300,120 400,90 500,60 600,30",
      yCoords: [180, 165, 140, 120, 90, 60, 30]
    };
  };

  const revChart = getRevenueChartPoints();
  const userChart = getUserChartPoints();

  return (
    <div className={`min-h-screen flex ${darkMode ? "bg-[#0b0c10] text-gray-200" : "bg-gray-50 text-gray-800"}`}>
      {/* ─── SIDEBAR ──────────────────────────────────────────────────────── */}
      <aside className={`w-64 border-r ${darkMode ? "bg-[#111217] border-gray-800" : "bg-white border-gray-200"} flex flex-col hidden md:flex shrink-0`}>
        {/* Sidebar Header */}
        <div className="h-16 flex items-center gap-3 px-6 border-b border-inherit">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-orbit-cyan to-orbit-purple flex items-center justify-center text-white font-black text-sm">
            O
          </div>
          <div>
            <span className="font-extrabold text-sm uppercase tracking-wider text-white">Orbit Admin</span>
            <p className="text-[9px] text-muted-foreground/60 leading-none">v1.0.4 - Premium</p>
          </div>
        </div>

        {/* Sidebar Navigation */}
        <nav className="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
          {[
            { id: "overview", label: "Overview", icon: LayoutDashboard },
            { id: "organizations", label: "Organizations", icon: Building2 },
            { id: "users", label: "Users & Roles", icon: Users },
            { id: "projects", label: "Projects", icon: Film },
            { id: "tasks", label: "Tasks", icon: CheckSquare },
            { id: "payments", label: "Payments", icon: CreditCard },
            { id: "analytics", label: "Live Analytics", icon: TrendingUp },
            { id: "settings", label: "Settings", icon: Settings },
            { id: "logs", label: "Audit Logs", icon: FileText },
            { id: "partner-codes", label: "Partner Codes", icon: KeyRound },
          ].map((item) => {
            const Icon = item.icon;
            const isActive = activeModule === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveModule(item.id)}
                className={`w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-semibold transition-all ${
                  isActive
                    ? "bg-gradient-to-r from-orbit-cyan/15 to-orbit-purple/10 text-orbit-cyan border-l-4 border-orbit-cyan"
                    : "text-muted-foreground hover:bg-white/5 hover:text-white"
                }`}
              >
                <Icon className={`w-4 h-4 ${isActive ? "text-orbit-cyan" : "text-gray-400"}`} />
                {item.label}
              </button>
            );
          })}
        </nav>

        {/* Sidebar Footer */}
        <div className="p-4 border-t border-inherit">
          <button className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-semibold text-red-400 hover:bg-red-500/5 transition-colors">
            <LogOut className="w-4 h-4" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* ─── MAIN CONTENT AREA ────────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0 overflow-x-hidden">
        {/* TOPBAR */}
        <header className={`h-16 border-b ${darkMode ? "bg-[#111217] border-gray-800" : "bg-white border-gray-200"} flex items-center justify-between px-6 z-20`}>
          {/* Left: Organization Switcher */}
          <div className="relative">
            <button
              onClick={() => setOrgDropdownOpen(!orgDropdownOpen)}
              className="flex items-center gap-2 px-3 py-1.5 rounded-lg hover:bg-white/5 text-sm font-bold text-white transition-colors"
            >
              <Building2 className="w-4 h-4 text-orbit-cyan" />
              {selectedOrg}
              <ChevronDown className="w-3.5 h-3.5 opacity-50" />
            </button>

            {orgDropdownOpen && (
              <>
                <div className="fixed inset-0 z-30" onClick={() => setOrgDropdownOpen(false)} />
                <div className={`absolute left-0 mt-2 w-56 rounded-xl border p-2 shadow-2xl z-40 ${
                  darkMode ? "bg-[#16171d] border-gray-800 text-white" : "bg-white border-gray-200 text-gray-800"
                }`}>
                  {["Orbit India Corp", "Orbit Global Inc", "Acme Production LLC"].map((org) => (
                    <button
                      key={org}
                      onClick={() => {
                        setSelectedOrg(org);
                        setOrgDropdownOpen(false);
                      }}
                      className="w-full text-left px-3 py-2 rounded-lg text-xs font-semibold hover:bg-white/5"
                    >
                      {org}
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>

          {/* Right: Quick actions, Search, Bell, Dark mode, Profile */}
          <div className="flex items-center gap-4">
            {/* Search bar */}
            <div className="relative hidden sm:block">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
              <input
                placeholder="Global search..."
                className={`pl-9 pr-4 py-1.5 w-60 rounded-full text-xs font-semibold border focus:outline-none ${
                  darkMode ? "bg-[#16171d] border-gray-800 text-white placeholder:text-gray-600 focus:border-orbit-cyan" : "bg-gray-100 border-gray-200 placeholder:text-gray-400"
                }`}
              />
            </div>

            {/* Dark Mode toggle */}
            <button
              onClick={() => setDarkMode(!darkMode)}
              className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-white/5 transition-colors"
            >
              {darkMode ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4 text-indigo-500" />}
            </button>

            {/* Bell notification */}
            <button className="w-8 h-8 rounded-full flex items-center justify-center hover:bg-white/5 relative">
              <Bell className="w-4 h-4" />
              <div className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-orbit-cyan" />
            </button>

            {/* Profile Dropdown */}
            <div className="relative">
              <button
                onClick={() => setProfileDropdownOpen(!profileDropdownOpen)}
                className="flex items-center gap-2"
              >
                <div className="w-8 h-8 rounded-full bg-gradient-to-r from-orbit-cyan to-orbit-purple flex items-center justify-center text-white font-extrabold text-xs shadow-lg">
                  AD
                </div>
              </button>

              {profileDropdownOpen && (
                <>
                  <div className="fixed inset-0 z-30" onClick={() => setProfileDropdownOpen(false)} />
                  <div className={`absolute right-0 mt-2 w-48 rounded-xl border p-2 shadow-2xl z-40 ${
                    darkMode ? "bg-[#16171d] border-gray-800 text-white" : "bg-white border-gray-200 text-gray-800"
                  }`}>
                    <div className="px-3 py-2 border-b border-gray-800/50 mb-1.5">
                      <p className="text-xs font-bold text-white leading-none">Admin User</p>
                      <p className="text-[10px] text-muted-foreground/60 mt-1">admin@orbitlogic.io</p>
                    </div>
                    <button className="w-full text-left px-3 py-2 rounded-lg text-xs hover:bg-white/5 flex items-center gap-2">
                      <Settings className="w-3.5 h-3.5" /> Settings
                    </button>
                    <button className="w-full text-left px-3 py-2 rounded-lg text-xs text-red-400 hover:bg-red-500/5 flex items-center gap-2">
                      <LogOut className="w-3.5 h-3.5" /> Sign Out
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </header>

        {/* CONTAINER */}
        <main className="flex-1 p-6 sm:p-8 overflow-y-auto">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeModule}
              initial={{ opacity: 0, y: 4 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.15, ease: "easeOut" }}
            >
              {/* 🟢 OVERVIEW MODULE ────────────────────────────── */}
              {activeModule === "overview" && (
                <div className="space-y-6">
                  {/* Top Stats Banner */}
                  <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                    <div>
                      <h2 className="text-2xl sm:text-3xl font-black text-white font-space">
                        Operations Command Center
                      </h2>
                      <p className="text-xs text-muted-foreground mt-1">
                        Monitoring multi-tenant SaaS activity metrics, revenue, and resources allocation
                      </p>
                    </div>
                    <Button onClick={fetchLogsAndData} disabled={loading} variant="outline" className="border-gray-800 text-gray-300 hover:bg-gray-900">
                      <RefreshCw className={`w-4 h-4 mr-2 ${loading ? "animate-spin" : ""}`} />
                      Sync
                    </Button>
                  </div>

                  {/* Summary Metric Cards */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
                    {[
                      { title: "Monthly Recurring Revenue", val: `₹${totalRevenue.toLocaleString()}`, desc: bookings.length > 0 ? "+12.4% vs last month" : "0% vs last month", icon: CreditCard, color: "text-orbit-cyan", trend: bookings.length > 0 ? [45, 60, 55, 75, 95, 110, 142] : Array(10).fill(0) },
                      { title: "Active Creators / Clients", val: metrics.totalClients, desc: "SaaS accounts active", icon: Users, color: "text-orbit-purple", trend: clients.length > 0 ? [120, 150, 180, 240, 310, 390, 480] : Array(10).fill(0) },
                      { title: "Active Production Shoots", val: metrics.totalBookings, desc: "Shoots currently dispatching", icon: Film, color: "text-green-400" },
                      { title: "Cloud Storage Allocation", val: `${(bookings.length * 12.5 / 1000).toFixed(2)} TB / 5 TB`, desc: `${cloudStoragePercent}% system capacity`, icon: HardDrive, color: "text-yellow-400" },
                    ].map((stat, i) => {
                      const Icon = stat.icon;
                      return (
                        <Card key={i} className="bg-[#111217] border-gray-800/80 text-white relative overflow-hidden glassmorphism shadow-xl">
                          <CardHeader className="pb-2">
                            <CardDescription className="text-gray-400 text-xs uppercase tracking-wider font-bold">{stat.title}</CardDescription>
                            <CardTitle className="text-2xl sm:text-3xl font-black font-space">{stat.val}</CardTitle>
                          </CardHeader>
                          <CardContent className="pb-4">
                            <div className="flex items-center justify-between">
                              <span className={`text-xs ${stat.color} flex items-center font-bold`}>
                                <Icon className="w-3.5 h-3.5 mr-1" />
                                {stat.desc}
                              </span>
                              {stat.trend && (
                                <svg className="w-16 h-8 text-orbit-cyan opacity-50" viewBox="0 0 100 50">
                                  <polyline
                                    fill="none"
                                    stroke="currentColor"
                                    strokeWidth="3"
                                    points={stat.trend.map((val, idx) => `${idx * 16},${50 - (val / 150) * 50}`).join(" ")}
                                  />
                                </svg>
                              )}
                            </div>
                          </CardContent>
                        </Card>
                      );
                    })}
                  </div>

                  {/* Main Directories & Analytics grid */}
                  <div className="grid lg:grid-cols-3 gap-6">
                    <Card className="lg:col-span-2 bg-[#111217] border-gray-800 text-white shadow-xl">
                      <CardHeader className="border-b border-gray-800 flex flex-row items-center justify-between">
                        <div>
                          <CardTitle>Active Videographers (Partners)</CardTitle>
                          <CardDescription className="text-gray-400 text-xs">Verify credentials and review ratings</CardDescription>
                        </div>
                        <div className="flex items-center gap-3">
                          <Button 
                            onClick={() => setIsGenerateModalOpen(true)}
                            className="bg-orbit-cyan text-black hover:bg-orbit-cyan/90 h-8 font-bold text-xs"
                          >
                            <Plus className="w-3.5 h-3.5 mr-1" /> Add Partner
                          </Button>
                          <div className="relative w-48 hidden sm:block">
                            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-500" />
                            <Input
                              placeholder="Filter list..."
                              value={searchQuery}
                              onChange={(e) => setSearchQuery(e.target.value)}
                              className="pl-8 h-8 text-xs bg-[#16171d] border-gray-800 text-white focus-visible:ring-orbit-cyan"
                            />
                          </div>
                        </div>
                      </CardHeader>
                      <CardContent className="p-0">
                        <div className="overflow-x-auto">
                          <table className="w-full text-left text-xs text-gray-300">
                            <thead className="bg-[#16171d] uppercase text-gray-400 border-b border-gray-800 font-bold">
                              <tr>
                                <th className="px-6 py-3.5">Partner / Contact</th>
                                <th className="px-6 py-3.5">Device Info</th>
                                <th className="px-6 py-3.5">Verification</th>
                                <th className="px-6 py-3.5">Completed Jobs</th>
                                <th className="px-6 py-3.5 text-right">Moderation</th>
                              </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-800/40">
                              {partners.filter(p => p.name?.toLowerCase().includes(searchQuery.toLowerCase()) || p.email?.toLowerCase().includes(searchQuery.toLowerCase())).slice(0, 5).map((partner) => (
                                <tr key={partner.id} className="hover:bg-white/5 transition-colors">
                                  <td className="px-6 py-3.5">
                                    <div className="font-bold text-white text-sm">{partner.name}</div>
                                    <div className="text-gray-500">{partner.email}</div>
                                  </td>
                                  <td className="px-6 py-3.5 text-gray-400">{partner.deviceInfo || "N/A"}</td>
                                  <td className="px-6 py-3.5">
                                    {partner.isVerified ? (
                                      <Badge className="bg-green-500/10 text-green-400 border border-green-500/20 text-[9px] px-1.5 py-0.5 rounded">Verified</Badge>
                                    ) : (
                                      <Badge className="bg-yellow-500/10 text-yellow-400 border border-yellow-500/20 text-[9px] px-1.5 py-0.5 rounded">Pending</Badge>
                                    )}
                                  </td>
                                  <td className="px-6 py-3.5 text-orbit-cyan font-bold">{partner.completedProjects} Jobs</td>
                                  <td className="px-6 py-3.5 text-right">
                                    <Button
                                      onClick={() => handleToggleVerification(partner.id, partner.isVerified)}
                                      disabled={togglingVerify === partner.id}
                                      size="sm"
                                      variant={partner.isVerified ? "destructive" : "default"}
                                      className={`h-7 text-[10px] ${partner.isVerified ? "bg-red-950 text-red-400 hover:bg-red-900" : "bg-orbit-cyan text-black hover:bg-orbit-cyan/95"}`}
                                    >
                                      {partner.isVerified ? "Revoke" : "Approve"}
                                    </Button>
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </CardContent>
                    </Card>

                    {/* Right side activity feed */}
                    <Card className="bg-[#111217] border-gray-800 text-white shadow-xl flex flex-col">
                      <CardHeader className="border-b border-gray-800">
                        <CardTitle className="flex items-center gap-2">
                          <Activity className="w-4.5 h-4.5 text-orbit-cyan" />
                          Audit Activity Log
                        </CardTitle>
                        <CardDescription className="text-gray-400 text-xs">Realtime SaaS transactions audit trail</CardDescription>
                      </CardHeader>
                      <CardContent className="flex-1 p-4 space-y-4 overflow-y-auto max-h-[320px]">
                        {logs.slice(0, 5).map((log) => (
                          <div key={log.id} className="flex gap-3 border-b border-gray-900 pb-3 last:border-0 last:pb-0">
                            <div className="w-2 h-2 rounded-full bg-orbit-cyan mt-1.5 shrink-0" />
                            <div className="min-w-0">
                              <p className="text-xs text-white font-semibold truncate">{log.action}</p>
                              <p className="text-[10px] text-gray-500 truncate">{log.user?.email || "anonymous"} · {log.entity}</p>
                              <span className="text-[9px] text-gray-600 font-mono">{new Date(log.createdAt).toLocaleTimeString()}</span>
                            </div>
                          </div>
                        ))}
                      </CardContent>
                    </Card>
                  </div>
                </div>
              )}

              {/* 🟢 ORGANIZATIONS MODULE ───────────────────────── */}
              {activeModule === "organizations" && (
                <Card className="bg-[#111217] border-gray-800 text-white shadow-xl">
                  <CardHeader className="border-b border-gray-800 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                    <div>
                      <CardTitle>SaaS Tenants & Organizations</CardTitle>
                      <CardDescription className="text-gray-400">Review registered company workspaces and active settings</CardDescription>
                    </div>
                    <Button className="bg-gradient-to-r from-orbit-cyan to-orbit-purple text-white font-bold text-xs h-9">
                      <Plus className="w-4 h-4 mr-1" /> New Organization
                    </Button>
                  </CardHeader>
                  <CardContent className="pt-6">
                    <div className="overflow-x-auto rounded-lg border border-gray-800">
                      <table className="w-full text-left text-sm text-gray-300">
                        <thead className="bg-[#16171d] text-xs uppercase text-gray-400 border-b border-gray-800">
                          <tr>
                            <th className="px-6 py-4">Workspace / Slug</th>
                            <th className="px-6 py-4">Status</th>
                            <th className="px-6 py-4">Created Date</th>
                            <th className="px-6 py-4">Owner ID</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-900">
                          <tr className="hover:bg-[#151515] transition-colors">
                            <td className="px-6 py-4">
                              <div className="font-bold text-white">Orbit India Corp</div>
                              <div className="text-xs text-gray-500">slug: orbit-india</div>
                            </td>
                            <td className="px-6 py-4"><Badge className="bg-green-500/10 text-green-400 border border-green-500/20">Active</Badge></td>
                            <td className="px-6 py-4">04-Jul-2026</td>
                            <td className="px-6 py-4 text-xs font-mono text-gray-500">usr-demo</td>
                          </tr>
                          <tr className="hover:bg-[#151515] transition-colors">
                            <td className="px-6 py-4">
                              <div className="font-bold text-white">Acme Production LLC</div>
                              <div className="text-xs text-gray-500">slug: acme-prod</div>
                            </td>
                            <td className="px-6 py-4"><Badge className="bg-green-500/10 text-green-400 border border-green-500/20">Active</Badge></td>
                            <td className="px-6 py-4">02-Jul-2026</td>
                            <td className="px-6 py-4 text-xs font-mono text-gray-500">usr-acme</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </CardContent>
                </Card>
              )}

              {/* 🟢 USERS MODULE ───────────────────────────────── */}
              {activeModule === "users" && (
                <Card className="bg-[#111217] border-gray-800 text-white shadow-xl">
                  <CardHeader className="border-b border-gray-800">
                    <CardTitle>SaaS Users Directory</CardTitle>
                    <CardDescription className="text-gray-400">Manage client accounts, employees, and custom roles</CardDescription>
                  </CardHeader>
                  <CardContent className="pt-6">
                    <div className="overflow-x-auto rounded-lg border border-gray-800">
                      <table className="w-full text-left text-sm text-gray-300">
                        <thead className="bg-[#16171d] text-xs uppercase text-gray-400 border-b border-gray-800">
                          <tr>
                            <th className="px-6 py-4">User</th>
                            <th className="px-6 py-4">Registration</th>
                            <th className="px-6 py-4">Audit Status</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-900">
                          {clients.map(c => (
                            <tr key={c.id} className="hover:bg-[#151515] transition-colors">
                              <td className="px-6 py-4">
                                <div className="font-semibold text-white">{c.name}</div>
                                <div className="text-xs text-gray-500">{c.email}</div>
                              </td>
                              <td className="px-6 py-4 text-xs text-gray-400">{new Date(c.createdAt).toLocaleDateString()}</td>
                              <td className="px-6 py-4"><Badge className="bg-orbit-cyan/15 text-orbit-cyan border-none">Active Client</Badge></td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </CardContent>
                </Card>
              )}

              {/* 🟢 PROJECTS MODULE ────────────────────────────── */}
              {activeModule === "projects" && (
                <Card className="bg-[#111217] border-gray-800 text-white shadow-xl">
                  <CardHeader className="border-b border-gray-800">
                    <CardTitle>Active Client Projects</CardTitle>
                    <CardDescription className="text-gray-400">Review status, owners, and deliverables</CardDescription>
                  </CardHeader>
                  <CardContent className="pt-6">
                    <div className="overflow-x-auto rounded-lg border border-gray-800">
                      <table className="w-full text-left text-sm text-gray-300">
                        <thead className="bg-[#16171d] text-xs uppercase text-gray-400 border-b border-gray-800">
                          <tr>
                            <th className="px-6 py-4">Project Name</th>
                            <th className="px-6 py-4">Tenant Org ID</th>
                            <th className="px-6 py-4">Status</th>
                            <th className="px-6 py-4">Active Plan</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-900">
                          {bookings.length === 0 ? (
                            <tr>
                              <td colSpan={4} className="px-6 py-8 text-center text-gray-500 font-semibold">
                                No active client projects found. Database is empty.
                              </td>
                            </tr>
                          ) : (
                            bookings.map((b) => (
                              <tr key={b.id} className="hover:bg-[#151515] transition-colors">
                                <td className="px-6 py-4">
                                  <div className="font-bold text-white">{b.packageName} Cinematic Reel</div>
                                  <div className="text-xs text-gray-500">ID: {b.id}</div>
                                </td>
                                <td className="px-6 py-4 text-xs font-mono text-gray-500">{b.clientName}</td>
                                <td className="px-6 py-4">
                                  <Badge className={
                                    b.status === "DELIVERED"
                                      ? "bg-green-500/10 text-green-400 border border-green-500/20"
                                      : b.status === "CANCELLED"
                                      ? "bg-red-500/10 text-red-400 border border-red-500/20"
                                      : "bg-orbit-cyan/15 text-orbit-cyan border-none animate-pulse"
                                  }>
                                    {b.status.replace(/_/g, " ")}
                                  </Badge>
                                </td>
                                <td className="px-6 py-4 text-xs">{b.packageName}</td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </CardContent>
                </Card>
              )}

              {/* 🟢 PAYMENTS MODULE ────────────────────────────── */}
              {activeModule === "payments" && (
                <Card className="bg-[#111217] border-gray-800 text-white shadow-xl">
                  <CardHeader className="border-b border-gray-800">
                    <CardTitle>SaaS Billing & Invoices</CardTitle>
                    <CardDescription className="text-gray-400">Track client subscription payments and payouts</CardDescription>
                  </CardHeader>
                  <CardContent className="pt-6">
                    <div className="overflow-x-auto rounded-lg border border-gray-800">
                      <table className="w-full text-left text-sm text-gray-300">
                        <thead className="bg-[#16171d] text-xs uppercase text-gray-400 border-b border-gray-800">
                          <tr>
                            <th className="px-6 py-4">Transaction ID</th>
                            <th className="px-6 py-4">Amount</th>
                            <th className="px-6 py-4">Payment Method</th>
                            <th className="px-6 py-4">Status</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-900">
                          {bookings.length === 0 ? (
                            <tr>
                              <td colSpan={4} className="px-6 py-8 text-center text-gray-500 font-semibold">
                                No billing transactions found. Database is empty.
                              </td>
                            </tr>
                          ) : (
                            bookings.map((b) => (
                              <tr key={b.id} className="hover:bg-[#151515] transition-colors">
                                <td className="px-6 py-4 text-xs font-mono text-gray-500">TXN-{b.id}</td>
                                <td className="px-6 py-4 text-green-400 font-bold">₹{b.packagePrice.toLocaleString()}</td>
                                <td className="px-6 py-4 text-xs">Stripe Gateway (UPI)</td>
                                <td className="px-6 py-4">
                                  <Badge className="bg-green-500/10 text-green-400 border border-green-500/20">
                                    {b.paymentStatus || "SUCCESS"}
                                  </Badge>
                                </td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </CardContent>
                </Card>
              )}

              {/* 🟢 ANALYTICS MODULE ───────────────────────────── */}
              {activeModule === "analytics" && (
                <div className="grid lg:grid-cols-2 gap-6">
                  <Card className="bg-[#111217] border-gray-800 text-white shadow-xl">
                    <CardHeader>
                      <CardTitle>Live Revenue Stream Graph</CardTitle>
                      <CardDescription className="text-xs text-gray-400">Total monthly revenue trend analytics</CardDescription>
                    </CardHeader>
                    <CardContent className="flex items-center justify-center p-6 h-64">
                      <div className="w-full h-full relative">
                        {/* Grid background */}
                        <div className="absolute inset-0 grid grid-rows-4 grid-cols-6 border-b border-l border-gray-800/60">
                          {Array.from({ length: 24 }).map((_, i) => (
                            <div key={i} className="border-t border-r border-gray-900/40" />
                          ))}
                        </div>
                        {/* SVG Polyline Chart */}
                        <svg className="w-full h-full text-orbit-cyan z-10 relative" viewBox="0 0 600 200" preserveAspectRatio="none">
                          <polyline
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="3.5"
                            points={revChart.points}
                          />
                          {/* Data point markers */}
                          {revChart.yCoords.map((y, idx) => (
                            <circle key={idx} cx={idx * 100} cy={y} r="5" className="fill-white stroke-orbit-cyan stroke-2" />
                          ))}
                        </svg>
                      </div>
                    </CardContent>
                  </Card>

                  <Card className="bg-[#111217] border-gray-800 text-white shadow-xl">
                    <CardHeader>
                      <CardTitle>Active User Growth Trends</CardTitle>
                      <CardDescription className="text-xs text-gray-400">Total active creator profiles over time</CardDescription>
                    </CardHeader>
                    <CardContent className="flex items-center justify-center p-6 h-64">
                      <div className="w-full h-full relative">
                        {/* Grid background */}
                        <div className="absolute inset-0 grid grid-rows-4 grid-cols-6 border-b border-l border-gray-800/60">
                          {Array.from({ length: 24 }).map((_, i) => (
                            <div key={i} className="border-t border-r border-gray-900/40" />
                          ))}
                        </div>
                        {/* SVG Polyline Chart */}
                        <svg className="w-full h-full text-orbit-purple z-10 relative" viewBox="0 0 600 200" preserveAspectRatio="none">
                          <polyline
                            fill="none"
                            stroke="currentColor"
                            strokeWidth="3.5"
                            points={userChart.points}
                          />
                          {/* Data point markers */}
                          {userChart.yCoords.map((y, idx) => (
                            <circle key={idx} cx={idx * 100} cy={y} r="5" className="fill-white stroke-orbit-purple stroke-2" />
                          ))}
                        </svg>
                      </div>
                    </CardContent>
                  </Card>
                </div>
              )}

              {/* 🟢 SETTINGS MODULE ────────────────────────────── */}
              {activeModule === "settings" && (
                <Card className="bg-[#111217] border-gray-800 text-white shadow-xl">
                  <CardHeader className="border-b border-gray-800">
                    <CardTitle>SaaS System Configurations</CardTitle>
                    <CardDescription className="text-gray-400 font-bold">Configure security overrides, pricing, and system variables</CardDescription>
                  </CardHeader>
                  <CardContent className="pt-6 space-y-4 max-w-xl">
                    <div className="flex items-center justify-between border-b border-gray-900 pb-3">
                      <div>
                        <p className="text-sm font-semibold">Maintenance Mode Override</p>
                        <p className="text-xs text-gray-500">Temporarily redirect non-admins to main lobby page</p>
                      </div>
                      <Badge className="bg-red-500/10 text-red-400 border border-red-500/20 rounded-full px-2.5 py-0.5 font-bold uppercase tracking-wider text-[9px]">Disabled</Badge>
                    </div>
                    <div className="flex items-center justify-between border-b border-gray-900 pb-3">
                      <div>
                        <p className="text-sm font-semibold">Enable Global Stripe Billing</p>
                        <p className="text-xs text-gray-500">Activate credit card recurring billing gateway features</p>
                      </div>
                      <Badge className="bg-green-500/10 text-green-400 border border-green-500/20 rounded-full px-2.5 py-0.5 font-bold uppercase tracking-wider text-[9px]">Active</Badge>
                    </div>
                    <div className="flex items-center justify-between border-b border-gray-900 pb-3">
                      <div>
                        <p className="text-sm font-semibold">Cloud Database Seeding</p>
                        <p className="text-xs text-gray-500">Seed packages, clients, and partners into Firestore</p>
                      </div>
                      <Button
                        onClick={handleSeedDatabase}
                        disabled={seeding}
                        className="bg-orbit-cyan text-black hover:bg-orbit-cyan/90 h-8 font-bold text-xs"
                      >
                        {seeding ? "Seeding..." : "Seed Database"}
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              )}

              {/* 🟢 AUDIT LOGS MODULE ──────────────────────────── */}
              {activeModule === "logs" && (
                <Card className="bg-[#111217] border-gray-800 text-white shadow-xl">
                  <CardHeader className="border-b border-gray-800 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                    <div>
                      <CardTitle>Operation Audit Logs</CardTitle>
                      <CardDescription className="text-gray-400">Complete historical operations logs of all data write events</CardDescription>
                    </div>
                    <div className="relative w-72">
                      <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
                      <Input
                        placeholder="Search logs action..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="pl-9 bg-[#16171d] border-gray-800 text-white placeholder:text-gray-600 focus-visible:ring-orbit-cyan"
                      />
                    </div>
                  </CardHeader>
                  <CardContent className="pt-6">
                    <div className="overflow-x-auto rounded-lg border border-gray-800">
                      <table className="w-full text-left text-sm text-gray-300">
                        <thead className="bg-[#16171d] text-xs uppercase text-gray-400 border-b border-gray-800">
                          <tr>
                            <th className="px-6 py-4">Timestamp</th>
                            <th className="px-6 py-4">User</th>
                            <th className="px-6 py-4">Action</th>
                            <th className="px-6 py-4">Target Entity</th>
                            <th className="px-6 py-4">Details</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-900">
                          {logs.filter(l => l.action?.toLowerCase().includes(searchQuery.toLowerCase())).map((log) => (
                            <tr key={log.id} className="hover:bg-[#151515] transition-colors">
                              <td className="px-6 py-4 text-gray-500 font-mono text-xs">
                                {new Date(log.createdAt).toLocaleString()}
                              </td>
                              <td className="px-6 py-4 font-semibold text-white">
                                {log.user?.email || "anonymous"}
                              </td>
                              <td className="px-6 py-4">
                                <Badge className="bg-[#242424] text-gray-300 border border-gray-800">{log.action}</Badge>
                              </td>
                              <td className="px-6 py-4 text-xs font-mono text-gray-400">
                                {log.entity} ({log.entityId || "N/A"})
                              </td>
                              <td className="px-6 py-4 text-xs text-gray-500 max-w-xs truncate">
                                {log.details || "None"}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </CardContent>
                </Card>
              )}

              {/* 🟢 PARTNER CODES MODULE ──────────────────────────── */}
              {activeModule === "partner-codes" && (
                <Card className="bg-[#111217] border-gray-800 text-white shadow-xl">
                  <CardHeader className="border-b border-gray-800 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                    <div>
                      <CardTitle>Partner Codes Management</CardTitle>
                      <CardDescription className="text-gray-400">Manage 2-tier verification codes for partner onboarding</CardDescription>
                    </div>
                    <Button onClick={() => setIsGenerateModalOpen(true)} className="bg-orbit-cyan text-black hover:bg-orbit-cyan/90 font-bold">
                      <Plus className="w-4 h-4 mr-2" /> Generate New Code
                    </Button>
                  </CardHeader>
                  <CardContent className="pt-6">
                    <div className="overflow-x-auto rounded-lg border border-gray-800">
                      <table className="w-full text-left text-sm text-gray-300">
                        <thead className="bg-[#16171d] text-xs uppercase text-gray-400 border-b border-gray-800">
                          <tr>
                            <th className="px-6 py-4">Security Code</th>
                            <th className="px-6 py-4">Target Email</th>
                            <th className="px-6 py-4">Status</th>
                            <th className="px-6 py-4">Trainer / Date</th>
                            <th className="px-6 py-4 text-right">Actions</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-900">
                          {partnerCodes.length === 0 ? (
                            <tr>
                              <td colSpan={5} className="px-6 py-8 text-center text-gray-500 font-semibold">
                                No partner enrollment codes found.
                              </td>
                            </tr>
                          ) : (
                            partnerCodes.map((code) => (
                              <tr key={code.id} className="hover:bg-[#151515] transition-colors">
                                <td className="px-6 py-4 font-mono font-bold text-white tracking-widest">
                                  {code.code}
                                </td>
                                <td className="px-6 py-4 text-xs font-semibold">
                                  {code.partnerEmail}
                                </td>
                                <td className="px-6 py-4">
                                  <Badge className={
                                    code.status === "UNUSED" ? "bg-orbit-cyan/10 text-orbit-cyan border-none"
                                    : code.status === "USED" ? "bg-green-500/10 text-green-400 border-none"
                                    : code.status === "REVOKED" ? "bg-red-500/10 text-red-400 border-none"
                                    : "bg-yellow-500/10 text-yellow-400 border-none"
                                  }>
                                    {code.status}
                                  </Badge>
                                </td>
                                <td className="px-6 py-4 text-xs text-gray-400">
                                  {code.trainerName}<br/>
                                  <span className="text-[10px] text-gray-500">{new Date(code.trainingDate).toLocaleDateString()}</span>
                                </td>
                                <td className="px-6 py-4 text-right">
                                  {code.status === "UNUSED" && (
                                    <Button
                                      onClick={() => handleRevokeCode(code.id)}
                                      size="sm"
                                      variant="destructive"
                                      className="h-7 text-[10px] bg-red-950 text-red-400 hover:bg-red-900"
                                    >
                                      Revoke
                                    </Button>
                                  )}
                                </td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  </CardContent>
                </Card>
              )}
            </motion.div>
          </AnimatePresence>
        </main>
      </div>

      {/* 🟢 OVERLAY MODAL FOR GENERATE CODE ───────────────────────── */}
      <AnimatePresence>
        {isGenerateModalOpen && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-[#111217] border border-gray-800 rounded-xl shadow-2xl w-full max-w-md overflow-hidden"
            >
              <div className="px-6 py-4 border-b border-gray-800 flex justify-between items-center">
                <h3 className="text-lg font-bold text-white">Enroll New Partner</h3>
                <button onClick={() => setIsGenerateModalOpen(false)} className="text-gray-400 hover:text-white">
                  ✕
                </button>
              </div>
              <form onSubmit={handleGenerateCode} className="p-6 space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-400 mb-1.5 uppercase">Partner Email</label>
                  <Input 
                    type="email" 
                    required 
                    placeholder="partner@example.com"
                    value={generateForm.partnerEmail}
                    onChange={(e) => setGenerateForm({...generateForm, partnerEmail: e.target.value})}
                    className="bg-[#16171d] border-gray-800 text-white focus-visible:ring-orbit-cyan"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-400 mb-1.5 uppercase">Assigned Trainer</label>
                  <Input 
                    type="text" 
                    required 
                    placeholder="John Doe"
                    value={generateForm.trainerName}
                    onChange={(e) => setGenerateForm({...generateForm, trainerName: e.target.value})}
                    className="bg-[#16171d] border-gray-800 text-white focus-visible:ring-orbit-cyan"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-400 mb-1.5 uppercase">Training Date</label>
                  <Input 
                    type="datetime-local" 
                    required
                    value={generateForm.trainingDate}
                    onChange={(e) => setGenerateForm({...generateForm, trainingDate: e.target.value})}
                    className="bg-[#16171d] border-gray-800 text-white focus-visible:ring-orbit-cyan [color-scheme:dark]"
                  />
                </div>
                
                <div className="pt-4 flex justify-end gap-3">
                  <Button type="button" variant="ghost" onClick={() => setIsGenerateModalOpen(false)} className="text-gray-400 hover:text-white hover:bg-white/5">
                    Cancel
                  </Button>
                  <Button type="submit" disabled={isGenerating} className="bg-orbit-cyan text-black hover:bg-orbit-cyan/90 font-bold">
                    {isGenerating ? "Generating..." : "Generate Code"}
                  </Button>
                </div>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}